import * as fs from 'fs';
import * as path from 'path';
import * as loglevel from 'loglevel';
import * as _ from 'lodash';
import {DotEnsime} from "../types";
import * as Promise from 'bluebird';

const log = loglevel.getLogger('ensime.startup');

import {startServerFromClasspath} from './server-startup-utils';
import {ChildProcess} from 'child_process';

// Start ensime server from given classpath file
export function startServerFromFile(classpathFile: string, dotEnsime: DotEnsime, ensimeServerFlags = ""): PromiseLike<ChildProcess> {  
  log.debug('starting server from file')
  return new Promise<ChildProcess>((resolve, reject) => {
      fs.readFile(classpathFile, {encoding: 'utf8'}, (err, classpathFileContents) => {
        if(err) 
          reject(err);
        let classpathList = _.split(classpathFileContents, path.delimiter);
        let pid = startServerFromClasspath(classpathList, dotEnsime, ensimeServerFlags)
        pid.then(resolve);
      })
  });
}

export function startServerFromAssemblyJar(assemblyJar: string, dotEnsime: DotEnsime, ensimeServerFlags = "") {
  let cp = [assemblyJar].concat(dotEnsime.compilerJars)
  return startServerFromClasspath(cp, dotEnsime, ensimeServerFlags)
}
