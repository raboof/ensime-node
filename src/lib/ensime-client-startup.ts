import fs = require('fs');
import path = require('path');
import loglevel = require('loglevel');
import chokidar = require('chokidar');
import {DotEnsime, ServerStarter} from './types';
import * as Promise from 'bluebird';

const log = loglevel.getLogger('ensime.startup');
import {createConnection, ServerConnection} from './server-api/server-connection';

function removeTrailingNewline(str: string) {
  return str.replace(/^\s+|\s+$/g, '');
} 
  
//  Start an ensime client given path to .ensime. If server already running, just use, else startup that too.
export default function(serverStarter: ServerStarter) {
  return function(parsedDotEnsime: DotEnsime, generalHandler: (msg: string) => any) : Promise<ServerConnection> {
    const p = Promise.defer<ServerConnection>(); 
    
    const httpPortFilePath = parsedDotEnsime.cacheDir + path.sep + "http";

    if(fs.existsSync(httpPortFilePath)) {
      // server running, no need to start
      const httpPort = removeTrailingNewline(fs.readFileSync(httpPortFilePath).toString())
      const clientPromise = createConnection(httpPort, generalHandler)
      clientPromise.then((client) => {
        log.debug("got a client ")
        p.resolve(client);
      });
    } else {
      let serverPid = undefined
      const whenAdded = function(file, f) {
        log.debug('starting watching for: '+file)
        const watcher = chokidar.watch(file, {
          persistent: true
        }).on('add', function(path) {
          log.debug('Seen: ', path);
          watcher.close();
          f();
        });
      }

      whenAdded(httpPortFilePath, function() {
        const httpPort = removeTrailingNewline(fs.readFileSync(httpPortFilePath).toString());
        const clientPromise = createConnection(httpPort, generalHandler, serverPid)
        clientPromise.then((client) => {
          log.debug("got a client");
          p.resolve(client);
        });
      });

      // no server running, start that first
      serverStarter(parsedDotEnsime).then((pid) => serverPid = pid)
    }

    return p.promise;
  };
};

