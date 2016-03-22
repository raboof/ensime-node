net = require('net')
Swank = require './lisp/swank-protocol'
fs = require 'fs-extra'
path = require 'path'
log = require('loglevel').getLogger('ensime.client')
temp = require 'temp'
WebSocket = require("ws")


tempDir = temp.mkdirSync()
getTempDir = -> tempDir

module.exports =
class Client
  constructor: (port, @httpPort, @generalMsgHandler, callback, @serverPid = undefined) ->
    @ensimeMessageCounter = 1
    @callbackMap = {}

    @websocket = new WebSocket("ws://localhost:" + @httpPort + "/jerky")

    @websocket.on "open", =>
      log.trace "connecting websocket…"
      callback(this)
  
    @websocket.on "message", (msg) =>
      log.trace("incoming: #{msg}")
      @handleIncoming(msg)
  
    @websocket.on "error", (error) ->
      log.error error
  
    @websocket.on "close", ->
      log.trace "websocket closed from server"
  
  handleIncoming: (env) ->
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
      @generalMsgHandler(json.payload)
  

  # Kills server if it was spawned from here.
  destroy: ->
    @websocket.terminate()
    @serverPid?.kill()

  
  postString: (msg, callback) =>
    msg = """{"req": #{msg}, "callId": #{@ensimeMessageCounter}}"""
    @callbackMap[@ensimeMessageCounter++] = callback
    log.trace("outgoing: " + msg)
    @websocket.send(msg)

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
        
        
