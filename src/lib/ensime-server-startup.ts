import fs = require('fs');
import path = require('path');
import loglevel = require('loglevel');
import _ = require('lodash');

var log = loglevel.getLogger('ensime.startup');

import serverStartupUtils = require('./server-startup-utils');
let startServerFromClasspath = serverStartupUtils.startServerFromClasspath;


// Start ensime server from given classpath file
export function startServerFromFile(cpF, dotEnsime, ensimeServerFlags, pidCallback) {  
  fs.readFile(cpF, {encoding: 'utf8'}, (err, classpathFileContents) => {
      if(! ensimeServerFlags)
        ensimeServerFlags = ""
      
      if(err) throw err;
        
      let classpathList = _.split(classpathFileContents, path.delimiter);
      let pid = startServerFromClasspath(classpathList, dotEnsime, ensimeServerFlags)
      pidCallback(pid)
  })
}


// Startup ensime with assembly jar + scala-compiler classpath, ie:
// java -classpath \
// /Library/Java/JavaVirtualMachines/jdk1.8.0_65.jdk/Contents/Home/lib/tools.jar:\
// /Users/viktor/dev/projects/ensime-server/target/scala-2.11/ensime_2.11-0.9.10-SNAPSHOT-assembly.jar:\
// /Users/viktor/.ivy2/cache/org.scala-lang/scala-compiler/jars/scala-compiler-2.11.7.jar:\
// /Users/viktor/.ivy2/cache/org.scala-lang/scala-library/jars/scala-library-2.11.7.jar:\
// /Users/viktor/.ivy2/cache/org.scala-lang/scala-reflect/jars/scala-reflect-2.11.7.jar:\
// /Users/viktor/.ivy2/cache/org.scala-lang/scalap/jars/scalap-2.11.7.jar \
// -Densime.config=/Users/viktor/dev/projects/ensime-test-project/.ensime \
// -Densime.protocol=jerk org.ensime.server.Server
export function startServerFromAssemblyJar(assemblyJar, dotEnsime, ensimeServerFlags, pidCallback) {
  let cp = [assemblyJar].concat(dotEnsime.compilerJars)
  let pid = startServerFromClasspath(cp, dotEnsime, ensimeServerFlags)
  pidCallback(pid)
}
