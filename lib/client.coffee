net = require('net')
{log, modalMsg} = require './utils'
Swank = require './ensime-client/lisp/swank-protocol'
_ = require 'lodash'


module.exports =
class Client
  constructor: (port, generalMsgHandler, @serverPid = undefined) ->
    @ensimeMessageCounter = 1
    @callbackMap = {}

    @parser = new Swank.SwankParser( (env) =>
      log("incoming: #{env}")
      json = JSON.parse(env)
      callId = json.callId
      # If RpcResponse - lookup in map, otherwise use some general function for handling general msgs

      if(callId)
        try
          @callbackMap[callId](json.payload)
        catch error
          log("error in callback: #{error}")
        finally
          delete @callbackMap[callId]
      else
        generalMsgHandler(json.payload)
    )

    @openSocket(port)

  # Kills server if it was spawned from here.
  destroy: ->
    @socket.destroy()
    @serverPid?.kill()

  openSocket: (port) ->
    console.log('connecting on port: ' + port)
    @socket = net.connect({port: port, allowHalfOpen: true} , ->
      console.log('client connected')
    )

    @socket.on('data', (data) =>
      @parser.execute(data)
    )

    @socket.on('end', ->
      console.log("Ensime server disconnected")
    )

    @socket.on('close', (data) ->
      console.log("Ensime server close event: " + data)
    )

    @socket.on('error', (data) ->
      if (data.code == 'ECONNREFUSED')
        modalMsg("Connection refused connecting to ensime, it is probably not running. Remove .ensime_cache/port and .ensime_cache/http and try again.")
      else if (data.code == 'EADDRNOTAVAIL')
        console.log(data)
        # happens when connecting too soon I think
      else
        console.log("Ensime server error event: " + data)
    )

    @socket.on('timeout', ->
      console.log("Ensime server timeout event")
    )

  postString: (msg, callback) =>
    swankMsg = Swank.buildMessage """{"req": #{msg}, "callId": #{@ensimeMessageCounter}}"""
    @callbackMap[@ensimeMessageCounter++] = callback
    log("outgoing: " + swankMsg)
    @socket.write(swankMsg, "UTF8")

  # Public:
  post: (msg, callback) ->
    @postString(JSON.stringify(msg), callback)



  goToTypeAtPoint: (textBuffer, bufferPosition) =>
    offset = textBuffer.characterIndexForPosition(bufferPosition)
    file = textBuffer.getPath()

    req =
      typehint: "SymbolAtPointReq"
      file: file
      point: offset

    @post(req, (msg) =>
      pos = msg.declPos
      # Sometimes no pos
      if(pos)
        @goToPosition(pos)
      else
        log("No declPos in response from Ensime, cannot go anywhere")
    )


  goToPosition: (pos) ->
    if(pos.typehint == "LineSourcePosition")
      atom.workspace.open(pos.file).then (editor) ->
        editor.setCursorBufferPosition([parseInt(pos.line), 0])
    else
      atom.workspace.open(pos.file).then (editor) ->
        targetEditorPos = editor.getBuffer().positionForCharacterIndex(parseInt(pos.offset))
        editor.setCursorBufferPosition(targetEditorPos)


  typecheckBuffer: (b, callback = () ->) =>
    msg =
      typehint: "TypecheckFileReq"
      fileInfo:
        file: b.getPath()
        contents: b.getText()

    @post(msg, callback)

  typecheckFile: (b) =>
    msg =
      typehint: "TypecheckFileReq"
      fileInfo:
        file: b.getPath()
    @post(msg, (result) ->)

  # TODO: make it incremental if perf. issue. Now this requests the whole thing every time
  # Probably need to branch out code-links and make something more custom with control over life cycle.
  # then we can ask for symbol-designations while typing incrementally
  # TODO: Move out to symbol-designations module
  getSymbolDesignations: (editor) ->
    b = editor.getBuffer()
    range = b.getRange()
    startO = b.characterIndexForPosition(range.start)
    endO = b.characterIndexForPosition(range.end)

    # TODO: contents:
    msg = {
      "typehint":"SymbolDesignationsReq"
      "requestedTypes": symbolTypehints
      "file": b.getPath()
      "start": startO
      "end": endO
    }


    new Promise (resolve, reject) =>
      @post(msg, (result) ->
        syms = result.syms

        markers = (sym) ->
          startPos = b.positionForCharacterIndex(parseInt(sym[1]))
          endPos = b.positionForCharacterIndex(parseInt(sym[2]))
          marker = editor.markBufferRange([startPos, endPos],
                  invalidate: 'inside',
                  class: "scala #{sym[0]}"
                  )
          decoration = editor.decorateMarker(marker,
            type: 'highlight',
            class: sym[0]
          )
          marker

        makeCodeLink = (marker) ->
          range: marker.getBufferRange()

        makers = (markers sym for sym in syms)
        codeLinks = (makeCodeLink marker for maker in makers)

        resolve(codeLinks)
      )



symbols = ["ObjectSymbol"
,"ClassSymbol"
,"TraitSymbol"
,"PackageSymbol"
,"ConstructorSymbol"
,"ImportedNameSymbol"
,"TypeParamSymbol"
,"ParamSymbol"
,"VarFieldSymbol"
,"ValFieldSymbol"
,"OperatorFieldSymbol"
,"VarSymbol"
,"ValSymbol"
,"FunctionCallSymbol"]

symbolTypehints = _.map(symbols, (symbol) -> {"typehint": "#{symbol}"})
