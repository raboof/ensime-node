path = require 'path'
_ = require 'lodash'
{spawn} = require('child_process')
log = require('loglevel').getLogger('server-startup')

# sort monkeys and add tools.jar
fixClasspath = (javaHome, classpathList) ->
  toolsJar = path.join(javaHome, 'lib', 'tools.jar')
  
  # Sort classpath so any jar containing monkey comes first
  sorter = (jarPath) -> not /monkey/.test(jarPath)
  classpathList.push(toolsJar)
  
  _.sortBy(classpathList, sorter).join(path.delimiter)
  

# Make an array of java command line args for spawn
javaArgsOf = (classpath, dotEnsimePath, ensimeServerFlags = "") ->
  args = ["-classpath", "#{classpath}", "-Densime.config=#{dotEnsimePath}", "-Densime.protocol=jerk"]
  if ensimeServerFlags.length > 0
    args.push ensimeServerFlags  ## Weird, but extra " " broke everyting
  args.push "org.ensime.server.Server"
  args
  

javaCmdOf = (dotEnsime) ->
  path.join(dotEnsime.javaHome, 'bin', 'java')


spawnServer = (javaCmd, args, detached = false) ->
  spawn(javaCmd, args, {detached: detached})
  

startServerFromClasspath = (classpath, dotEnsime, serverFlags = "") ->
  fixedClasspath = fixClasspath(dotEnsime.javaHome, classpath)
  cmd = javaCmdOf(dotEnsime)
  args = javaArgsOf(fixedClasspath, dotEnsime.dotEnsimePath, serverFlags)
  log.info("Starting Ensime server with #{cmd} #{args}")
  pid = spawnServer(cmd, args)
  logServer(pid, path.join(dotEnsime.cacheDir,'server.log'))
  
logServer = (pid, path) ->
  serverLog = fs.createWriteStream(path)
  pid.stdout.pipe(serverLog)
  pid.stderr.pipe(serverLog)
  pid.stdin.end()
  
  
module.exports = {
  fixClasspath
  javaArgsOf
  javaCmdOf,
  spawnServer,
  startServerFromClasspath
}
