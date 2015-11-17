# Download and startup of ensime server
fs = require('fs')
path = require('path')
{exec, spawn} = require('child_process')
{log, modalMsg, projectPath, withSbt} = require('./utils')
EnsimeServerUpdateLogView = require('./views/ensime-server-update-log-view')
lisp = require './lisp/lisp'
{sexpToJObject} = require './lisp/swank-extras'
remote = require 'remote'




dotEnsimeToCPFileName = ->
  withDotEnsime (scalaVersion, javaHome) ->
    mkClasspathFileName(scalaVersion, ensimeServerVersion())


mkClasspathFileName = (scalaVersion, ensimeServerVersion) ->
  atom.packages.resolvePackagePath('Ensime') + path.sep + "classpath_#{scalaVersion}_#{ensimeServerVersion}"


ensimeCache = -> projectPath() + path.sep + '.ensime_cache'
ensimeServerLogFile = -> ensimeCache() + path.sep + 'server.log'












# Check that we have a classpath that is newer than atom ensime package.json (updated on release), otherwise delete it
classpathFileOk = (cpF) ->
  if not fs.existsSync(cpF)
    false
  else
    cpFStats = fs.statSync(cpF)
    fine = cpFStats.isFile && cpFStats.ctime > fs.statSync(packageDir + path.sep + 'package.json').mtime
    if not fine
      fs.unlinkSync(cpF)
    fine





startEnsimeServer = (pidCallback) ->
  withDotEnsime (scalaVersion, javaHome) =>
    if not fs.existsSync(ensimeCache())
      fs.mkdirSync(ensimeCache())

    toolsJar = "#{javaHome}#{path.sep}lib#{path.sep}tools.jar"
    cpF = mkClasspathFileName(scalaVersion, ensimeServerVersion())
    log("classpathfile name: #{cpF}")

    checkForServerCP = (trysLeft) =>
      log("check for server classpath file #{cpF}. trys left: " + trysLeft)
      if(trysLeft == 0)
        modalMsg("Server hasn't been updated yet. If this is the first run, maybe you're downloading the internet. Check update
        log and try again!")
      else if not fs.existsSync(cpF)
          @serverUpdateTimeout = setTimeout (=>
            checkForServerCP(trysLeft - 1)
          ), 2000
      else
        # Classpath file for running Ensime server is in place
        classpath = toolsJar + path.delimiter + fs.readFileSync(cpF, {encoding: 'utf8'})
        javaCmd = "#{javaHome}#{path.sep}bin#{path.sep}java"
        ensimeServerFlags = "#{atom.config.get('Ensime.ensimeServerFlags')}"
        ensimeConfigFile = projectPath() + path.sep + '.ensime'
        args = ["-classpath", "#{classpath}", "-Densime.config=#{ensimeConfigFile}", "-Densime.protocol=jerk"]
        if ensimeServerFlags.length > 0
           args.push ensimeServerFlags  ## Weird, but extra " " broke everyting

        args.push "org.ensime.server.Server"

        log("Starting ensime server with: #{javaCmd} #{args.join(' ')}")

        serverLog = fs.createWriteStream(ensimeServerLogFile())

        pid = spawn(javaCmd, args, {
         detached: atom.config.get('Ensime.runServerDetached')
        })
        pid.stdout.pipe(serverLog) # TODO: have a screenbuffer tail -f this file.
        pid.stderr.pipe(serverLog)
        pid.stdin.end()
        pidCallback(pid)


    if(not classpathFileOk(cpF))
      withSbt (sbtCmd) =>
        updateEnsimeServer(sbtCmd, scalaVersion, ensimeServerVersion())
        checkForServerCP(20) # 40 sec should be enough?
    else
      checkForServerCP(20) # 40 sec should be enough?


module.exports = {
  startEnsimeServer: startEnsimeServer,
  classpathFileName: dotEnsimeToCPFileName
}
