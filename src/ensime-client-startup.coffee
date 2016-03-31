path = require 'path'
fs = require 'fs'
log = require('loglevel').getLogger('ensime.startup')
createClient = require './client'
chokidar = require 'chokidar'

# Start an ensime client given path to .ensime. If server already running, just use, else startup that too.
module.exports = startClient = (startEnsimeServer) -> (parsedDotEnsime, generalHandler, callback) ->
  removeTrailingNewline = (str) -> str.replace(/^\s+|\s+$/g, '')
  
  httpPortFilePath = parsedDotEnsime.cacheDir + path.sep + "http"

  if fs.existsSync(httpPortFilePath)
    # server running, no need to start
    httpPort = removeTrailingNewline(fs.readFileSync(httpPortFilePath).toString())
    createClient(httpPort, generalHandler).then(callback)
  else
    serverPid = undefined

    whenAdded = (file, f) ->
      log.trace('starting watching for: '+file)
      
      watcher = chokidar.watch(file, {
        persistent: true
      }).on('add', (path) ->
        log.trace 'Seen: ', path
        watcher.close()
        f()
      )

    whenAdded(httpPortFilePath, ->
      httpPort = removeTrailingNewline(fs.readFileSync(httpPortFilePath).toString())
      createClient(httpPort, generalHandler, serverPid).then(callback)
    )

    # no server running, start that first
    startEnsimeServer(parsedDotEnsime, (pid) -> serverPid = pid)
