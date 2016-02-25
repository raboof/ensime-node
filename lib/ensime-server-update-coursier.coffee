{packageDir, mkClasspathFileName, log} = require './utils'
EnsimeServerUpdateLogView = require './views/ensime-server-update-log-view'
{spawn} = require('child_process')
fs = require('fs')
path = require('path')
log = require('loglevel').getLogger('ensime.server-update')

# Updates ensime server, invoke callback when done
updateEnsimeServer = (parsedDotEnsime, ensimeServerVersion, classpathFile, whenUpdated = () -> ) ->
  scalaVersion = parsedDotEnsime.scalaVersion
  javaCmd = "#{parsedDotEnsime.javaHome}#{path.sep}bin#{path.sep}java"
  
  tempdir =  packageDir() + path.sep + "ensime_update_coursier"

  @serverUpdateLog = new EnsimeServerUpdateLogView()

  pane = atom.workspace.getActivePane()
  pane.addItem @serverUpdateLog
  pane.activateItem @serverUpdateLog

  if not fs.existsSync(tempdir)
    fs.mkdirSync(tempdir)

  logPid = (pid) ->
    pid.stdout.on 'data', (chunk) => @serverUpdateLog.addRow(chunk.toString('utf8'))
    pid.stderr.on 'data', (chunk) => @serverUpdateLog.addRow(chunk.toString('utf8'))
    
    
  if fs.existsSync(tempdir + path.sep + tempdir)
    runCoursier()
  else
    # """curl -L -o coursier https://git.io/vgvpD && chmod +x coursier"""
    coursierUrl = 'https://git.io/vgvpD'
    getCoursier = spawn('curl', ['-L', '-o', 'coursier', coursierUrl], {cwd: tempdir})
    logPid(getCoursier)
    getCoursier.on 'close', (exitCode) ->
      if(exitCode == 0)
        chmod = spawn('chmod', ['+x', 'coursier'], {cwd: tempdir})
        logPid(chmod)
        chmod.on 'close', (chmodExitCode) ->
          if(chmodExitCode == 0)
            runCoursier()
          else
            atom.notifications.addError("Failed to chmod coursier", {
              dismissable: true
              detail: "Exit code: #{chmodExitCode}"
              })
      else
        atom.notifications.addError("Failed to get Coursier", {
          dismissable: true
          detail: "Exit code: #{exitCode}"
        })
  
  
  runCoursier = () ->
    scalaEdition = scalaVersion.substring(0, 4)
    args =
      [
        '-noverify', # https://github.com/alexarchambault/coursier/issues/176#issuecomment-188772685
        '-jar', './coursier',
        'fetch',
        '-m', 'update-changing',
        '-r', 'file:///$HOME/.m2/repository',
        '-r', 'https://oss.sonatype.org/content/repositories/snapshots',
        '-r', 'https://jcenter.bintray.com/',
        "org.ensime:ensime_#{scalaEdition}:0.9.10-SNAPSHOT",
        '-V', "org.scala-lang:scala-compiler:#{scalaVersion}",
        '-V', "org.scala-lang:scala-library:#{scalaVersion}",
        '-V', "org.scala-lang:scala-reflect:#{scalaVersion}",
        '-V', "org.scala-lang:scalap:#{scalaVersion}"
      ]

    spaceSeparatedClassPath = ""
    
    log.trace([javaCmd], args, tempdir)
    pid = spawn(javaCmd, args, {cwd: tempdir})
    pid.stdout.on 'data', (chunk) ->
      log.trace(chunk.toString('utf8'))
      spaceSeparatedClassPath += chunk.toString('utf8')
    logPid(pid)
    pid.stdin.end()
    pid.on 'close', (exitCode) ->
      if(exitCode == 0)
        classpath = _.join(_.split(spaceSeparatedClassPath, '\n'), path.delimiter)
        fs.writeFile(classpathFile, classpath, whenUpdated)
      else
        atom.notifications.addError("Ensime server update failed", {
          dismissable: true
          detail: "Exit code:" + exitCode
        })
        



module.exports = updateEnsimeServer
