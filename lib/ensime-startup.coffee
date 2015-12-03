# Download and startup of ensime server
fs = require('fs')
path = require('path')
{exec, spawn} = require('child_process')
{log, modalMsg, projectPath, packageDir,
 withSbt, mkClasspathFileName} = require('./utils')
EnsimeServerUpdateLogView = require('./views/ensime-server-update-log-view')
lisp = require './ensime-client/lisp/lisp'
{sexpToJObject} = require './ensime-client/lisp/swank-extras'
remote = require 'remote'
{parseDotEnsime} = require './ensime-client/dotensime-utils'
Client = require './client'
{updateEnsimeServer} = require './ensime-server-update'



###
## Pseudo:
This code is pretty complex with lots of continuation passing.
Here is some kind of pseudo for easier understanding:

startClient(dotEnsime) ->
  if(serverRunning(dotEnsime))
    doStartClient(dotEnsime)
  else
    startServer(dotEnsime, () ->
      doStartClient(dotEnsime)
    )

startServer(dotEnsime, whenStarted) ->
  if(classpathOk(dotEnsime))
    doStartServer(dotEnsime, whenStarted)
  else
    updateServer(dotEnsime, () ->
      doStartServer(dotEnsime, whenStarted)
    )

###

# ensime server version from settings
ensimeServerVersion = ->
  atom.config.get('Ensime.ensimeServerVersion')



# Check that we have a classpath that is newer than atom
# ensime package.json (updated on release), otherwise delete it
classpathFileOk = (cpF) ->
  if not fs.existsSync(cpF)
    false
  else
    cpFStats = fs.statSync(cpF)
    fine = cpFStats.isFile && cpFStats.ctime > fs.statSync(packageDir() + path.sep + 'package.json').mtime
    if not fine
      fs.unlinkSync(cpF)
    fine

mkPortFilePath = (cacheDir) -> cacheDir + path.sep + "port"

mkServerLogFilePath = (cacheDir) -> cacheDir + path.sep + 'server.log'


# Start an ensime client given path to .ensime. If server already running, just use, else startup that too.
startClient = (parsedDotEnsime, generalHandler, callback) ->
  portFilePath = mkPortFilePath(parsedDotEnsime.cacheDir)

  if fs.existsSync(portFilePath)
    # server running, no need to start
    port = fs.readFileSync(portFilePath).toString()
    doStartClient(parsedDotEnsime, port, generalHandler, callback)
  else
    # no server running, start that first
    startEnsimeServer(parsedDotEnsime, (port) ->
      doStartClient(parsedDotEnsime, port, generalHandler, callback)
    )

# Do start a client given that server is running
doStartClient = (parsedDotEnsime, port, generalHandler, callback) ->
  callback(new Client(port, generalHandler))



# Start ensime server. If classpath file is out of date, make an update first
startEnsimeServer = (parsedDotEnsime, portCallback) ->
  if not fs.existsSync(parsedDotEnsime.cacheDir)
    fs.mkdirSync(cacheDir)

  cpF = mkClasspathFileName(parsedDotEnsime.scalaVersion, ensimeServerVersion())
  log("classpathfile name: #{cpF}")

  pidCallback = (pid) -> portCallback(pid.port)

  if(not classpathFileOk(cpF))
    # update server and start
    withSbt (sbtCmd) ->
      updateEnsimeServer(sbtCmd, parsedDotEnsime.scalaVersion, ensimeServerVersion(), () -> doStartEnsimeServer(parsedDotEnsime, pidCallback))
  else
    # just start server
    doStartEnsimeServer(parsedDotEnsime, pidCallback)

# Start ensime server when classpath is up to date
doStartEnsimeServer = (parsedDotEnsime, pidCallback) ->
  cpF = mkClasspathFileName(parsedDotEnsime.scalaVersion, ensimeServerVersion())
  toolsJar = "#{parsedDotEnsime.javaHome}#{path.sep}lib#{path.sep}tools.jar"
  classpath = toolsJar + path.delimiter + fs.readFileSync(cpF, {encoding: 'utf8'})
  javaCmd = "#{parsedDotEnsime.javaHome}#{path.sep}bin#{path.sep}java"
  ensimeServerFlags = "#{atom.config.get('Ensime.ensimeServerFlags')}"
  args = ["-classpath", "#{classpath}", "-Densime.config=#{parsedDotEnsime.dotEnsimePath}", "-Densime.protocol=jerk"]
  if ensimeServerFlags.length > 0
    args.push ensimeServerFlags  ## Weird, but extra " " broke everyting

  args.push "org.ensime.server.Server"

  log("Starting ensime server with: #{javaCmd} #{args.join(' ')}")

  serverLog = fs.createWriteStream(mkServerLogFilePath(parsedDotEnsime.cacheDir))

  pid = spawn(javaCmd, args, {
    detached: atom.config.get('Ensime.runServerDetached')
  })
  pid.stdout.pipe(serverLog) # TODO: have a screenbuffer tail -f this file.
  pid.stderr.pipe(serverLog)
  pid.stdin.end()
  pidCallback(pid)


module.exports = {
  startClient
}
