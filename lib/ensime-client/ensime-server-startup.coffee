log = require('loglevel').getLogger('ensime.startup')
{spawn} = require('child_process')
fs = require 'fs'
path = require 'path'

# Start ensime server when classpath is up to date
module.exports = doStartEnsimeServer = (cpF, parsedDotEnsime, pidCallback, ensimeServerFlags = "") ->
  toolsJar = "#{parsedDotEnsime.javaHome}#{path.sep}lib#{path.sep}tools.jar"
  
  fs.readFile(cpF, {encoding: 'utf8'}, (err, classpathFileContents) ->
    if(err)
      throw err
      
    log.trace ['classpathFileContents', classpathFileContents]
    
    classpathList = _.split(classpathFileContents, path.delimiter)
    # Sort classpath so any jar containing monkey comes first
    sorter = (jarPath) -> not /monkey/.test(jarPath)
    tokenizedClasspathEntries = _.split(classpathFileContents, path.delimiter)
    tokenizedClasspathEntries.push(toolsJar)
    log.trace ['tokenizedClasspathEntries', tokenizedClasspathEntries]
    
    classpath = _.sortBy(tokenizedClasspathEntries, sorter).join(path.delimiter)
    log.trace("classpath: #{classpath}")
    javaCmd = "#{parsedDotEnsime.javaHome}#{path.sep}bin#{path.sep}java"
    
    args = ["-classpath", "#{classpath}", "-Densime.config=#{parsedDotEnsime.dotEnsimePath}", "-Densime.protocol=jerk"]
    if ensimeServerFlags.length > 0
      args.push ensimeServerFlags  ## Weird, but extra " " broke everyting

    args.push "org.ensime.server.Server"

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
