net = require('net')
Swank = require './lisp/swank-protocol'
fs = require 'fs-extra'
path = require 'path'
log = require('loglevel').getLogger('ensime.client')
temp = require 'temp'

tempDir = temp.mkdirSync()
getTempDir = -> tempDir

# TODO:
# Client should be stripped of everything Atom specific
# to be a node ensime-node client ready to be separated into
# npm module used bs vscode for instance
module.exports =
class Client
  constructor: (port, @httpPort, generalMsgHandler, @serverPid = undefined) ->
    @ensimeMessageCounter = 1
    @callbackMap = {}

    @parser = new Swank.SwankParser( (env) =>
      log.trace("incoming: #{env}")
      json = JSON.parse(env)
      callId = json.callId
      # If RpcResponse - lookup in map, otherwise use some general function for handling general msgs

      if(callId)
        try
          @callbackMap[callId](json.payload)
        catch error
          log.trace("error in callback: #{error}")
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
    log.trace('connecting on port: ' + port)
    @socket = net.connect({port: port, allowHalfOpen: true} , ->
      log.trace('client connected')
    )

    @socket.on('data', (data) =>
      @parser.execute(data)
    )

    @socket.on('end', ->
      log.trace("Ensime server disconnected")
    )

    @socket.on('close', (data) ->
      log.trace("Ensime server close event: " + data)
    )

    @socket.on('error', (data) ->
      if (data.code == 'ECONNREFUSED')
        log.error("Connection refused connecting to ensime, it is probably not running. Remove .ensime_cache/port and .ensime_cache/http and try again.")
      else if (data.code == 'EADDRNOTAVAIL')
        log.trace(data)
        # happens when connecting too soon I think
      else
        log.trace("Ensime server error event: " + data)
    )

    @socket.on('timeout', ->
      log.trace("Ensime server timeout event")
    )

  postString: (msg, callback) =>
    swankMsg = Swank.buildMessage """{"req": #{msg}, "callId": #{@ensimeMessageCounter}}"""
    @callbackMap[@ensimeMessageCounter++] = callback
    log.trace("outgoing: " + swankMsg)
    @socket.write(swankMsg, "UTF8")

  # Public:
  post: (msg, callback) ->
    @postString(JSON.stringify(msg), callback)


  getCompletions: (filePath, bufferText, offset, noOfAutocompleteSuggestions, callback) =>
    tempFilePath = getTempDir() + filePath
    fs.outputFile(tempFilePath, bufferText, (err) =>
      if (err)
        throw err
      else
        msg =
          typehint: "CompletionsReq"
          fileInfo:
            file: filePath
            contentsIn: tempFilePath
          point: offset
          maxResults: noOfAutocompleteSuggestions
          caseSens: false
          reload: true
        @post(msg, callback)
    )
    
    
 
  getSymbolAtPoint: (path, offset, callback) ->
    req =
      typehint: "SymbolAtPointReq"
      file: path
      point: offset
    @post(req, (msg) ->
      if msg.typehint == 'SymbolInfo'
        callback(msg)
      else
        # if msg.typehint == 'FalseResponse'
        # do nothing
    )
    

  typecheckBuffer: (path, text, callback = ->) =>
    tempFilePath = getTempDir() + path
    fs.outputFile(tempFilePath, text, (err) =>
      if (err)
        throw err
      else
        msg =
          typehint: "TypecheckFileReq"
          fileInfo:
            file: path
            contentsIn: tempFilePath
        @post(msg, callback)
    )


  
  typecheckFile: (path) =>
    msg =
      typehint: "TypecheckFileReq"
      fileInfo:
        file: path
    @post(msg, (result) ->)


  symbolByName: (qualifiedName, callback) ->
    msg =
      typehint: 'SymbolByNameReq'
      typeFullName: qualifiedName
    @post(msg, callback)
    
    
  formatSourceFile: (path, contents, callback) ->
    tempFilePath = getTempDir() + path
    fs.outputFile(tempFilePath, contents, (err) =>
      if (err)
        throw err
      else
        req =
          typehint: "FormatOneSourceReq"
          file:
            file: path
            contentsIn: tempFilePath
        @post(req, callback)
    )
        
        
