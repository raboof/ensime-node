import Promise = require('bluebird');
import fs = require('fs');

const fsWriteFile : (filename: string, data: any, callback: (err: NodeJS.ErrnoException) => void) => void = fs.writeFile

/**
 * Promisified file io
 */
export const writeFile = Promise.promisify(fsWriteFile)
export const readFile = Promise.promisify(fs.readFile)