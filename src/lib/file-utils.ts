import Promise = require('bluebird');
import fs = require('fs');
import loglevel = require('loglevel');

const log = loglevel.getLogger('ensime.startup');

const fsWriteFile : (filename: string, data: any, callback: (err: NodeJS.ErrnoException) => void) => void = fs.writeFile

/**
 * Promisified file io
 */
export const writeFile : (f: String, data: any) => PromiseLike<{}> = Promise.promisify(fsWriteFile)
export const readFile : (f: String) => PromiseLike<Buffer> = Promise.promisify(fs.readFile)

export function ensureExists(path: string) : PromiseLike<{}> {
  return new Promise((resolve, reject) => {
    log.trace('ensureExists called', path)
    fs.exists(path, (exists) => {
      if(! exists) {
        fs.mkdir(path, (err) => {
          if(err) {
            console.log(err)
            reject(err);
          } else {
            resolve(path);
          }
        });
      } else {
        resolve(path);
      } 
    });
  });
}