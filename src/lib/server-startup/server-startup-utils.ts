import path = require('path');
import _ = require('lodash');
import * as Promise from 'bluebird';

import {ChildProcess, spawn} from 'child_process';

import loglevel = require('loglevel')
const log = loglevel.getLogger('server-startup')
import fs = require('fs');
import {DotEnsime} from '../types';
import {ensureExists} from '../file-utils'

/**
* Sort monkeys and add tools.jar
*/
export function fixClasspath(javaHome: string, classpathList: string[]) {  
  const toolsJar = path.join(javaHome, 'lib', 'tools.jar');
  
  //Sort classpath so any jar containing monkey comes first
  const monkey = new RegExp('monkey')
  const sorter = (jarPath) => ! monkey.test(jarPath)
  classpathList.push(toolsJar)
  return _.sortBy(classpathList, sorter).join(path.delimiter)
}
  
/**
 *  Make an array of java command line args for spawn
 */
export function javaArgsOf(classpath: string, dotEnsimePath, ensimeServerFlags = "") {
  const args = ["-classpath", classpath, `-Densime.config=${dotEnsimePath}`, "-Densime.protocol=jerk"]
  if(ensimeServerFlags.length > 0) 
    args.push(ensimeServerFlags) // ## Weird, but extra " " broke everyting
  args.push("org.ensime.server.Server")
  return args
}

export function javaCmdOf(dotEnsime: DotEnsime) {
  return path.join(dotEnsime.javaHome, 'bin', 'java')
} 

function spawnServer(javaCmd: string, args: string[], detached = false) {
  return spawn(javaCmd, args, {detached: detached})
}
  
function logServer(pid, cacheDir) {
 fs.exists(cacheDir, (exists) => {
    if(exists) {
      const serverLog = fs.createWriteStream(path.join(cacheDir, "server.log"))
      pid.stdout.pipe(serverLog)
      pid.stderr.pipe(serverLog)
      return pid.stdin.end()
    } else {
      fs.mkdir(cacheDir, (err) => {
        return logServer(pid, cacheDir);
      });
    }
 });
}




export function startServerFromClasspath(classpath: string[], dotEnsime: DotEnsime, serverFlags = "") : PromiseLike<ChildProcess> {
  return new Promise<ChildProcess>((resolve, reject) => {
    const fixedClasspath = fixClasspath(dotEnsime.javaHome, classpath)
    const cmd = javaCmdOf(dotEnsime)
    const args = javaArgsOf(fixedClasspath, dotEnsime.dotEnsimePath, serverFlags)
    log.info(`Starting Ensime server with ${cmd} ${_.join(args, " ")}`)

    ensureExists(dotEnsime.cacheDir).then( () => {
      const pid = spawnServer(cmd, args)
      logServer(pid, dotEnsime.cacheDir)
      resolve(pid)
    });

  });
}