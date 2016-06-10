net = require('net')
fs = require 'fs-extra'
path = require 'path'
log = require('loglevel').getLogger('ensime.client')
temp = require 'temp'
{WebsocketClient} = require './network/NetworkClient'

temp.track()
tempDir = temp.mkdirSync()
getTempDir = -> tempDir

getTempPath = (file) ->
  if(process.platform == 'win32')
    path.join(getTempDir(), file.replace(':', ""))
  else
    path.join(getTempDir(), file)

module.exports = createClient = (httpPort, generalMsgHandler, serverPid = undefined) ->
  new Promise (resolve, reject) ->
    
    callbackMap = {}

    ensimeMessageCounter = 1
    
    publicApi = -> {
      httpPort,
      post,
      destroy,
      getCompletions,
      getSymbolAtPoint,
      typecheckBuffer,
      typecheckFile,
      symbolByName,
      formatSourceFile
    }
    
    handleIncoming = (msg) ->
      json = JSON.parse(msg)
      callId = json.callId
      # If RpcResponse - lookup in map, otherwise use some general function for handling general msgs

      if(callId)
        try
          callbackMap[callId](json.payload)
        catch error
          log.trace("error in callback: #{error}")
        finally
          delete callbackMap[callId]
      else
        generalMsgHandler(json.payload)
    
    onConnect = -> resolve(publicApi())
    netClient = new WebsocketClient(httpPort, onConnect, handleIncoming)

    # Kills server if it was spawned from here.
    destroy = ->
      netClient.destroy()
      serverPid?.kill()

    
    postString = (msg, callback) ->
      msg = """{"req": #{msg}, "callId": #{ensimeMessageCounter}}"""
      callbackMap[ensimeMessageCounter++] = callback
      log.trace("outgoing: " + msg)
      netClient.send(msg)

    # Public:
    post = (msg, callback) ->
      postString(JSON.stringify(msg), callback)


    getCompletions = (filePath, bufferText, offset, noOfAutocompleteSuggestions, callback) ->
      tempFilePath = getTempPath(filePath)
      fs.outputFile(tempFilePath, bufferText, (err) ->
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
          post(msg, callback)
      )
      
      
   
    getSymbolAtPoint = (path, offset, callback) ->
      req =
        typehint: "SymbolAtPointReq"
        file: path
        point: offset
      post(req, (msg) ->
        if msg.typehint == 'SymbolInfo'
          callback(msg)
        else
          # if msg.typehint == 'FalseResponse'
          # do nothing
      )
      

    typecheckBuffer = (path, text, callback = ->) ->
      tempFilePath = getTempPath(path)
      fs.outputFile(tempFilePath, text, (err) ->
        if (err)
          throw err
        else
          msg =
            typehint: "TypecheckFileReq"
            fileInfo:
              file: path
              contentsIn: tempFilePath
          post(msg, callback)
      )
    
    typecheckFile = (path) ->
      msg =
        typehint: "TypecheckFileReq"
        fileInfo:
          file: path
      post(msg, (result) ->)


    symbolByName = (qualifiedName, callback) ->
      msg =
        typehint: 'SymbolByNameReq'
        typeFullName: qualifiedName
      post(msg, callback)
      
      
      
    formatSourceFile = (path, contents, callback) ->
      tempFilePath = getTempPath(path)
      fs.outputFile(tempFilePath, contents, (err) ->
        if (err)
          throw err
        else
          req =
            typehint: "FormatOneSourceReq"
            file:
              file: path
              contentsIn: tempFilePath
          post(req, callback)
      )
          
        
