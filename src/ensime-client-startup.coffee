path = require 'path'
fs = require 'fs'
log = require('loglevel').getLogger('ensime.startup')
gaze = require 'gaze'
createClient = require './client'

# Start an ensime client given path to .ensime. If server already running, just use, else startup that too.
module.exports = startClient = (startEnsimeServer) -> (parsedDotEnsime, generalHandler, callback) ->
  removeTrailingNewline = (str) -> str.replace(/^\s+|\s+$/g, '')
  
  portFilePath = parsedDotEnsime.cacheDir + path.sep + "port"
  httpPortFilePath = parsedDotEnsime.cacheDir + path.sep + "http"

  if fs.existsSync(portFilePath) && fs.existsSync(httpPortFilePath)
    # server running, no need to start
    port = removeTrailingNewline(fs.readFileSync(portFilePath).toString())
    httpPort = removeTrailingNewline(fs.readFileSync(httpPortFilePath).toString())
    createClient(port, httpPort, generalHandler).then(callback)
  else
    serverPid = undefined

    whenAllAdded = (files, f) ->
      log.trace('starting watching for: '+files)
      file = files.pop() # NB: mutates files
      
      gaze.watch(file, (err, watcher) ->
        watcher.on('add', (path) ->
          log.trace 'Seen: ', path
          watcher.end()
          if 0 == files.length
            log.trace('All files seen. Starting client')
            f()
          else
            whenAllAdded(files, f)
        )
      )

    whenAllAdded([portFilePath, httpPortFilePath], ->
      port = fs.readFileSync(portFilePath).toString()
      httpPort = removeTrailingNewline(fs.readFileSync(httpPortFilePath).toString())
      createClient(port, httpPort, generalHandler, serverPid).then(callback)
    )

    # no server running, start that first
    startEnsimeServer(parsedDotEnsime, (pid) -> serverPid = pid)
