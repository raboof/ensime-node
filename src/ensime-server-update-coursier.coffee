{spawn} = require('child_process')
fs = require('fs')
path = require('path')
loglevel = require 'loglevel'
_ = require 'lodash'



javaArgs = (dotEnsime, updateChanging) ->
  scalaVersion = dotEnsime.scalaVersion
  scalaEdition = dotEnsime.scalaEdition
  args =
    [
      '-noverify', # https://github.com/alexarchambault/coursier/issues/176#issuecomment-188772685
      '-jar', './coursier',
      'fetch'
    ]
  args.push ['-m', 'update-changing']... if updateChanging
  args.push [
    '-r', 'file:///$HOME/.m2/repository',
    '-r', 'https://oss.sonatype.org/content/repositories/snapshots',
    '-r', 'https://jcenter.bintray.com/',
    "org.ensime:ensime_#{scalaEdition}:0.9.10-SNAPSHOT",
    '-V', "org.scala-lang:scala-compiler:#{scalaVersion}",
    '-V', "org.scala-lang:scala-library:#{scalaVersion}",
    '-V', "org.scala-lang:scala-reflect:#{scalaVersion}",
    '-V', "org.scala-lang:scalap:#{scalaVersion}"
  ]...
  args
  
  
# Updates ensime server, invoke callback when done
module.exports = (tempdir, getPidLogger, failure) ->
  log = loglevel.getLogger('ensime.server-update')
  log.info('update ensime server, tempdir: ' + tempdir)

  (parsedDotEnsime, ensimeServerVersion, classpathFile, whenUpdated = -> ) ->
    
    logPid = getPidLogger()
    
    runCoursier = ->
      javaCmd = if(parsedDotEnsime.javaHome)
        "#{parsedDotEnsime.javaHome}#{path.sep}bin#{path.sep}java"
      else
        "java"
        
    
      spaceSeparatedClassPath = ""
      
      args = javaArgs(parsedDotEnsime, true)
      
      log.trace([javaCmd], args, tempdir)
      pid = spawn(javaCmd, args, {cwd: tempdir})
      pid.stdout.on 'data', (chunk) ->
        log.trace(chunk.toString('utf8'))
        spaceSeparatedClassPath += chunk.toString('utf8')
      logPid(pid)
      pid.stdin.end()
      pid.on 'close', (exitCode) ->
        if(exitCode == 0)
          classpath = _.join(_.split(_.trim(spaceSeparatedClassPath), /\s/), path.delimiter)
          log.trace ['classpath', classpath]
          fs.writeFile(classpathFile, classpath, whenUpdated)
        else
          failure("Ensime server update failed", exitCode)
        

    log.info("checking tempdir: " + tempdir)
    if not fs.existsSync(tempdir)
      fs.mkdirSync(tempdir)

    if fs.existsSync(tempdir + path.sep + 'coursier')
      runCoursier()
    else
      coursierUrl = 'https://git.io/vgvpD'
      download = require 'download' # Need to be here because node thread
      download(mode: '0755').get(coursierUrl).dest(tempdir).rename('coursier').run (err) ->
        if(err)
          failure("Failed to download coursier", err)
        else
          runCoursier()
