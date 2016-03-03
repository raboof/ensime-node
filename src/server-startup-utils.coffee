path = require 'path'
_ = require 'lodash'

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



module.exports = {
  fixClasspath
  javaArgsOf
  javaCmdOf
}
