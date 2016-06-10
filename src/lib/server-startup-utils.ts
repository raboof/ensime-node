import path = require('path');
import _ = require('lodash');

import {ChildProcess, spawn} from 'child_process';

import loglevel = require('loglevel')
const log = loglevel.getLogger('server-startup')
import fs = require('fs');

/*
* Sort monkeys and add tools.jar
*/
export function fixClasspath(javaHome, classpathList) {  
  const toolsJar = path.join(javaHome, 'lib', 'tools.jar');
  
  //Sort classpath so any jar containing monkey comes first
  const monkey = new RegExp('monkey')
  const sorter = (jarPath) => ! monkey.test(jarPath)
  classpathList.push(toolsJar)
  return _.sortBy(classpathList, sorter).join(path.delimiter)
}
  
// # Make an array of java command line args for spawn
export function javaArgsOf(classpath, dotEnsimePath, ensimeServerFlags = "") {
  const args = ["-classpath", classpath, `-Densime.config=${dotEnsimePath}`, "-Densime.protocol=jerk"]
  if(ensimeServerFlags.length > 0) 
    args.push(ensimeServerFlags) // ## Weird, but extra " " broke everyting
  args.push("org.ensime.server.Server")
  return args
}

export function javaCmdOf(dotEnsime) {
  return path.join(dotEnsime.javaHome, 'bin', 'java')
} 

export function spawnServer(javaCmd, args, detached = false) {
  return spawn(javaCmd, args, {detached: detached})
}
  
export function startServerFromClasspath(classpath, dotEnsime, serverFlags = "") {
  const fixedClasspath = fixClasspath(dotEnsime.javaHome, classpath)
  const cmd = javaCmdOf(dotEnsime)
  const args = javaArgsOf(fixedClasspath, dotEnsime.dotEnsimePath, serverFlags)
  log.info(`Starting Ensime server with ${cmd} ${args}`)
  const pid = spawnServer(cmd, args)
  logServer(pid, path.join(dotEnsime.cacheDir,'server.log'))
  return pid
}
  
export function logServer(pid, path) {
  const serverLog = fs.createWriteStream(path)
  pid.stdout.pipe(serverLog)
  pid.stderr.pipe(serverLog)
  return pid.stdin.end()
}

export function removeTrailingNewline(str: string) {
  return str.replace(/^\s+|\s+$/g, '');
} 
  