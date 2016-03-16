import fs = require('fs');
import lisp = require ('./lisp/lisp');
import _ = require('lodash');
import Promise = require('bluebird');
import glob = require('glob');
import swankExtras = require('./lisp/swank-extras')
import {spawn} from 'child_process';

const sexpToJObject = swankExtras.sexpToJObject

export function readDotEnsime(path: string) {
  let raw = fs.readFileSync(path)
  let rows = raw.toString().split(new RegExp("\r?\n"))
  let filtered = rows.filter((l) => l.indexOf(';;') != 0)
  return filtered.join('\n')
}

export function parseDotEnsime(path) {
  // scala version from .ensime config file of project
  const dotEnsime = readDotEnsime(path)
  const dotEnsimeLisp = lisp.readFromString(dotEnsime)
  const dotEnsimeJs = sexpToJObject(dotEnsimeLisp)
  const subprojects = dotEnsimeJs[':subprojects']
  const sourceRoots = _.flattenDeep(_.map(subprojects, (sp) => sp[':source-roots']))
  const scalaVersion = dotEnsimeJs[':scala-version']
  const scalaEdition = scalaVersion.substring(0, 4)

  return {
    name: <string> dotEnsimeJs[':name'],
    scalaVersion: scalaVersion,
    scalaEdition: scalaEdition,
    javaHome: dotEnsimeJs[':java-home'],
    javaFlags: dotEnsimeJs[':java-flags'],
    rootDir: dotEnsimeJs[':root-dir'],
    cacheDir: dotEnsimeJs[':cache-dir'],
    compilerJars: dotEnsimeJs[':scala-compiler-jars'],
    dotEnsimePath: path,
    sourceRoots: sourceRoots
  };
}

// Gives promise of .ensime paths
export function allDotEnsimesInPaths(paths: [string]): Promise<{path: string}[]> {
  const globTask = Promise.promisify<[string], string, {}>(glob)
  const promises = paths.map ((dir) =>
    globTask(
      '.ensime', {
        cwd: dir,
        matchBase: true,
        nodir: true,
        realpath: true,
        ignore: '**/{node_modules,.ensime_cache,.git,target,.idea}/**'  
      })
  )
  const promise = Promise.all(promises)
  const result = promise.then((dotEnsimesUnflattened) => {
    const thang = _.flattenDeep<string>(dotEnsimesUnflattened);
    function toObj(path: string) {
      return {path: <string> path}
    }
    return thang.map(toObj)
  })
  return result;
}
  
  

export function dotEnsimesFilter(path: string, stats: any) {
  !stats.isDirectory() && ! _.endsWith(path, '.ensime')
}
