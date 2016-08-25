import fs = require('fs');
import lisp = require ('./lisp/lisp');
import _ = require('lodash');
import * as Promise from 'bluebird';
import glob = require('glob');
import swankExtras = require('./lisp/swank-extras')
import {spawn} from 'child_process';
import {DotEnsime} from './types';
const sexpToJObject = swankExtras.sexpToJObject
import {readFile} from './file-utils';

function readDotEnsime(path: string) : PromiseLike<string> {
  
  return readFile(path).then((raw) => {
    let rows = raw.toString().split(new RegExp("\r?\n"))
    let filtered = rows.filter((l) => l.indexOf(';;') != 0)
    return filtered.join('\n')
  })
}

export function parseDotEnsime(path: string) : PromiseLike<DotEnsime> {
  // scala version from .ensime config file of project
  return readDotEnsime(path).then((dotEnsime) => {

    const dotEnsimeLisp = lisp.readFromString(dotEnsime)
    const dotEnsimeJs = sexpToJObject(dotEnsimeLisp)
    const subprojects = dotEnsimeJs[':subprojects']
    const sourceRoots = _.flattenDeep(_.map(subprojects, (sp) => sp[':source-roots']))
    const scalaVersion = dotEnsimeJs[':scala-version']
    const scalaEdition = scalaVersion.substring(0, 4)

    return {
      name: <string> dotEnsimeJs[':name'],
      scalaVersion: <string> scalaVersion,
      scalaEdition: <string> scalaEdition,
      javaHome: <string> dotEnsimeJs[':java-home'],
      javaFlags: <string> dotEnsimeJs[':java-flags'],
      rootDir: <string> dotEnsimeJs[':root-dir'],
      cacheDir: <string> dotEnsimeJs[':cache-dir'],
      compilerJars: <string> dotEnsimeJs[':scala-compiler-jars'],
      dotEnsimePath: <string> path,
      sourceRoots:  <[string]> sourceRoots
    };
  }); 
}

// Gives promise of .ensime paths
export function allDotEnsimesInPaths(paths: [string]): PromiseLike<{path: string}[]> {
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
