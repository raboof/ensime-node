log = require('loglevel').getLogger('ensime.startup')
{spawn} = require('child_process')
fs = require 'fs'
path = require 'path'


{fixClasspath, javaArgsOf, javaCmdOf} = require './server-startup'

module.exports = doStartEnsimeServer = (cpF, parsedDotEnsime, pidCallback, ensimeServerFlags = "") ->
  
  fs.readFile(cpF, {encoding: 'utf8'}, (err, classpathFileContents) ->
    if(err)
      throw err
      
    log.trace ['classpathFileContents', classpathFileContents]
    
    classpathList = _.split(classpathFileContents, path.delimiter)
    classpath = fixClasspath(parsedDotEnsime.javaHome, classpathList)
    
    
    args = javaArgsOf(classpath, parsedDotEnsime.dotEnsimePath, ensimeServerFlags)
    
    log.trace("Starting ensime server with: #{javaCmd} #{args.join(' ')}")

    serverLog = fs.createWriteStream(parsedDotEnsime.cacheDir + path.sep + 'server.log')

    pid = spawn(javaCmd, args, {
      detached: atom.config.get('Ensime.runServerDetached')
    })
    pid.stdout.pipe(serverLog)
    pid.stderr.pipe(serverLog)
    pid.stdin.end()
    pidCallback(pid)
  )
