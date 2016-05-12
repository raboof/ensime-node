import fs = require('fs');
import path = require('path');
import loglevel = require('loglevel');
import chokidar = require('chokidar');
import utils = require('./server-startup-utils');
import {DotEnsime} from './types';


const log = loglevel.getLogger('ensime.startup');
const createClient = require('./client');

export type ServerStarter = (dotEnsime: DotEnsime, callback: (pid: string) => void) => void

//  Start an ensime client given path to .ensime. If server already running, just use, else startup that too.
export default function(serverStarter: ServerStarter) {
  return function(parsedDotEnsime, generalHandler: (msg: string) => any, callback: (client: any) => any) {
     
    const httpPortFilePath = parsedDotEnsime.cacheDir + path.sep + "http";

    if(fs.existsSync(httpPortFilePath)) {
      // server running, no need to start
      const httpPort = utils.removeTrailingNewline(fs.readFileSync(httpPortFilePath).toString())
      createClient(httpPort, generalHandler).then(callback)
    } else {
      let serverPid = undefined
      const whenAdded = function(file, f) {
        log.trace('starting watching for: '+file)
        const watcher = chokidar.watch(file, {
          persistent: true
        }).on('add', function(path) {
          log.trace('Seen: ', path);
          watcher.close();
          f();
        });
      }

      whenAdded(httpPortFilePath, function() {
        const httpPort = utils.removeTrailingNewline(fs.readFileSync(httpPortFilePath).toString());
        createClient(httpPort, generalHandler, serverPid).then(callback);
      });

      // no server running, start that first
      serverStarter(parsedDotEnsime, (pid) => serverPid = pid)
    }
  };
};

