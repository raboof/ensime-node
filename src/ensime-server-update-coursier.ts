import fs = require('fs');
import path = require('path');

import {spawn} from 'child_process';
import _ = require('lodash');
import loglevel = require('loglevel');
import {DotEnsime} from './types';
const download = require('download');
      
      
function javaArgs(dotEnsime, updateChanging) {
  const scalaVersion = dotEnsime.scalaVersion
  const scalaEdition = dotEnsime.scalaEdition
  const args =
    [
      '-noverify', // https://github.com/alexarchambault/coursier/issues/176#issuecomment-188772685
      '-jar', './coursier',
      'fetch'
    ]
  if(updateChanging) {
    args.push('-m', 'update-changing');
  }
  args.push (
    '-r', 'file:///$HOME/.m2/repository',
    '-r', 'https://oss.sonatype.org/content/repositories/snapshots',
    '-r', 'https://jcenter.bintray.com/',
    `org.ensime:ensime_${scalaEdition}:0.9.10-SNAPSHOT`, // TODO: Should be parameterized?
    '-V', `org.scala-lang:scala-compiler:${scalaVersion}`,
    '-V', `org.scala-lang:scala-library:${scalaVersion}`,
    '-V', `org.scala-lang:scala-reflect:${scalaVersion}`,
    '-V', `org.scala-lang:scalap:${scalaVersion}`
  );
  return args;
}
   
// Updates ensime server, invoke callback when done
export default function updateServer(tempdir: string, getPidLogger: () => (string) => void, failure: (string, int) => void) {
  
  const log = loglevel.getLogger('ensime.server-update')
  log.info('update ensime server, tempdir: ' + tempdir)

  function doUpdateServer(parsedDotEnsime: DotEnsime, ensimeServerVersion: string, classpathFile: string, whenUpdated: () => void ) {
    
    function runCoursier() {
      const javaCmd = (parsedDotEnsime.javaHome) ? 
          path.join(parsedDotEnsime.javaHome, 'bin', 'java')
        :
          "java"
    
      let spaceSeparatedClassPath = ""
      
      const args = javaArgs(parsedDotEnsime, true)
      
      log.trace('java command to spawn', javaCmd, args, tempdir)
      const pid = spawn(javaCmd, args, {cwd: tempdir})
      pid.stdout.on('data', (chunk) => {
        log.trace('got data from java process', chunk.toString('utf8'))
        spaceSeparatedClassPath += chunk.toString('utf8')
      })
      pid.stderr.on('data', (chunk) => {
        log.error('error from spawned java coursier process: ', chunk.toString('utf8'))
      })
      
      pid.stdin.end()
      
      pid.on('close', (exitCode) => {
        if(exitCode == 0) {
          const classpath = _.join(_.split(_.trim(spaceSeparatedClassPath), /\s/), path.delimiter)
          log.trace ['classpath', classpath]
          fs.writeFile(classpathFile, classpath, whenUpdated)
        } else {
          log.error('Ensime server update failed, exitCode: ', exitCode) 
          failure("Ensime server update failed", exitCode)
        }
      });
    }

    log.trace("checking tempdir: " + tempdir)
    if(! fs.existsSync(tempdir)) {
      log.trace("tempdir didn't exist, creating: " + tempdir)
      fs.mkdirSync(tempdir)
    }

    if(fs.existsSync(tempdir + path.sep + 'coursier')) {
      log.trace("pre-existing coursier binary, downloading: " + tempdir)
      runCoursier()
    } else {
      log.trace("no pre-existing coursier binary, downloading: " + tempdir)
      // # coursierUrl = 'https://git.io/vgvpD' # Java 7
      const coursierUrl = "https://git.io/v2L2P" // Java 6
      
      download({mode: '0755'}).get(coursierUrl).dest(tempdir).rename('coursier').run((err) => {
        if(err) {
          log.error("failed to download coursier")
          failure("Failed to download coursier", err)
        } else {
          log.trace("downloaded coursier, now running:")
          runCoursier()
        }
      });
    }
  }
  
  return doUpdateServer;

}