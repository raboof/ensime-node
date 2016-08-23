import fs = require('fs');
import path = require('path');
import * as Promise from 'bluebird';

import {spawn} from 'child_process';
import _ = require('lodash');
import loglevel = require('loglevel');
import {DotEnsime} from './types';
const download = require('download');
import {ensureExists} from './file-utils'

function javaArgs(dotEnsime: DotEnsime, serverVersion: String, updateChanging: boolean) {
  const scalaVersion = dotEnsime.scalaVersion
  const scalaEdition = dotEnsime.scalaEdition
  const args =
    [
      '-noverify', // https://github.com/alexarchambault/coursier/issues/176#issuecomment-188772685
      '-jar', './coursier',
      'fetch'
    ]
  if (updateChanging) {
    args.push('-m', 'update-changing');
  }
  args.push(
    '-r', 'file:///$HOME/.m2/repository',
    '-r', 'https://oss.sonatype.org/content/repositories/snapshots',
    '-r', 'https://jcenter.bintray.com/',
    `org.ensime:ensime_${scalaEdition}:${serverVersion}`,
    '-V', `org.scala-lang:scala-compiler:${scalaVersion}`,
    '-V', `org.scala-lang:scala-library:${scalaVersion}`,
    '-V', `org.scala-lang:scala-reflect:${scalaVersion}`,
    '-V', `org.scala-lang:scalap:${scalaVersion}`
  );
  return args;
}

// Updates ensime server, invoke callback when done
export default function updateServer(tempdir: string, failure: (string, int) => void) {
  const logger = loglevel.getLogger('ensime.server-update')
  logger.debug('update ensime server, tempdir: ' + tempdir)

  return function doUpdateServer(parsedDotEnsime: DotEnsime, ensimeServerVersion: string, classpathFile: string): PromiseLike<any> {
    logger.debug('trying to update server with coursier…')

    return ensureExists(parsedDotEnsime.cacheDir).then((cacheDir) => {

      
      console.log('cachedir: ', cacheDir)
      return new Promise((resolve, reject) => {
        function runCoursier() {
          const javaCmd = (parsedDotEnsime.javaHome) ?
            path.join(parsedDotEnsime.javaHome, 'bin', 'java')
            :
            "java"

          let spaceSeparatedClassPath = ""

          const args = javaArgs(parsedDotEnsime, ensimeServerVersion, true)

          logger.debug('java command to spawn', javaCmd, args, tempdir)
          const pid = spawn(javaCmd, args, { cwd: tempdir })
          pid.stdout.on('data', (chunk) => {
            logger.debug('got data from java process', chunk.toString('utf8'))
            spaceSeparatedClassPath += chunk.toString('utf8')
          })
          pid.stderr.on('data', (chunk) => {
            logger.debug('coursier: ', chunk.toString('utf8'))
          })

          pid.stdin.end()

          pid.on('close', (exitCode) => {
            if (exitCode == 0) {
              const classpath = _.join(_.split(_.trim(spaceSeparatedClassPath), /\s/), path.delimiter)
              logger.debug['classpath', classpath]
              fs.writeFile(classpathFile, classpath, resolve)
            } else {
              logger.error('Ensime server update failed, exitCode: ', exitCode)
              failure("Ensime server update failed", exitCode)
              reject(exitCode)
            }
          });
        }

        logger.debug("checking tempdir: " + tempdir)
        if (!fs.existsSync(tempdir))  {
          logger.debug("tempdir didn't exist, creating: " + tempdir)
          fs.mkdirSync(tempdir)
        }

        if (fs.existsSync(tempdir + path.sep + 'coursier')) {
          logger.debug("pre-existing coursier binary, downloading: " + tempdir)
          runCoursier()
        } else {
          logger.trace("no pre-existing coursier binary, downloading: " + tempdir)
          // # coursierUrl = 'https://git.io/vgvpD' # Java 7
          const coursierUrl = "https://git.io/v2L2P" // Java 6

          download({ mode: '0755' }).get(coursierUrl).dest(tempdir).rename('coursier').run((err) => {
            if (err) {
              logger.error("failed to download coursier")
              failure("Failed to download coursier", err)
              reject(err)
            } else {
              logger.debug("downloaded coursier, now running:")
              runCoursier()
            }
          });
        }
      });
    });
  }

}