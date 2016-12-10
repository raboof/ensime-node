import fs = require('fs');
import path = require('path');
import loglevel = require('loglevel');
import chokidar = require('chokidar');
import {DotEnsime, ServerStarter} from './types';
import * as Promise from 'bluebird';
import {ensureExists} from './file-utils'
import {ChildProcess} from 'child_process';

const log = loglevel.getLogger('ensime.startup');
import {createConnection, ServerConnection} from './server-api/server-connection';

function removeTrailingNewline(str: string) {
  return str.replace(/^\s+|\s+$/g, '');
} 
  
//  Start an ensime client given path to .ensime. If server already running, just use, else startup that too.
export default function(serverStarter: ServerStarter) {
  log.debug('creating client starter function from ServerStarter')
  return function(parsedDotEnsime: DotEnsime, generalHandler: (msg: string) => any) : PromiseLike<ServerConnection> {

    log.debug('trying to start client')
    return new Promise<ServerConnection>((resolve, reject) => {

      ensureExists(parsedDotEnsime.cacheDir).then(() => {

        const httpPortFilePath = parsedDotEnsime.cacheDir + path.sep + "http";

        if(fs.existsSync(httpPortFilePath)) {
          // server running, no need to start
          log.debug("port file already there, starting client");
          const httpPort = removeTrailingNewline(fs.readFileSync(httpPortFilePath).toString())
          const connectionPromise = createConnection(httpPort, generalHandler)
          connectionPromise.then((connection) => {
            log.debug("got a connection")
            resolve(connection);
          });
        } else {
          function whenFailed(proc: ChildProcess) {
            return new Promise((resolve, reject) => {
              // TODO poll instead of checking once
              // TODO typescript doesn't appear to believe ChildProcess has an `exitCode` field?
              if (proc.exitCode != 0) {
                resolve();
              }
            });
          }

          function whenAdded(file: string) {
            return new Promise((resolve, reject) => {
              log.debug('starting watching for : '+file)
            
              const watcher = chokidar.watch(file, {
                persistent: true
              }).on('all', (event, path) => {
                log.debug('Seen: ', path);
                watcher.close();
                resolve();
              });

              log.debug("watching…")
            });
          }

          log.debug('no server running, start that first…')
          serverStarter(parsedDotEnsime).then((serverPid) => {
            whenAdded(httpPortFilePath).then( () => {
              log.debug("got a port file");
              const httpPort = removeTrailingNewline(fs.readFileSync(httpPortFilePath).toString());
              const connectionPromise = createConnection(httpPort, generalHandler, serverPid)
              connectionPromise.then((connection) => {
                log.debug("got a connection");
                resolve(connection);
              });
            });
            whenFailed(serverPid).then( () => {
              log.debug("Starting ensime failed", serverPid);
              reject(serverPid);
            })
          })
        }

      }, (failToCreateCacheDir) => {
        reject(failToCreateCacheDir)
      });
    }); 
  };
};

