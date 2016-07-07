import Promise = require('bluebird');
import fs = require('fs');

const fsWriteFile : (filename: string, data: any, callback: (err: NodeJS.ErrnoException) => void) => void = fs.writeFile

/**
 * Promisified file io
 */
export const writeFile = Promise.promisify(fsWriteFile)
export const readFile = Promise.promisify(fs.readFile)

export function ensureExists(path: string) {
  return new Promise((resolve, reject) => {
    fs.exists(path, (exists) => {
      if(! exists) {
        fs.mkdir(path, (err) => {
          if(err)
            reject(err);
          else
            resolve();
        });
      } else {
        resolve();
      } 
    });
  });
}