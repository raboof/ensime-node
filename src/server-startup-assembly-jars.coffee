log = require('loglevel').getLogger('ensime.startup')
{spawn} = require('child_process')
fs = require 'fs'
path = require 'path'


#
# Startup ensime with assembly jar + scala-compiler classpath, ie:
# java -classpath \
# /Users/viktor/dev/projects/ensime-server/target/scala-2.11/ensime_2.11-0.9.10-SNAPSHOT-assembly.jar:\
# /Users/viktor/.ivy2/cache/org.scala-lang/scala-compiler/jars/scala-compiler-2.11.7.jar:\
# /Users/viktor/.ivy2/cache/org.scala-lang/scala-library/jars/scala-library-2.11.7.jar:\
# /Users/viktor/.ivy2/cache/org.scala-lang/scala-reflect/jars/scala-reflect-2.11.7.jar:\
# /Users/viktor/.ivy2/cache/org.scala-lang/scalap/jars/scalap-2.11.7.jar \
# -Densime.config=/Users/viktor/dev/projects/ensime-test-project/.ensime \
# -Densime.protocol=jerk org.ensime.server.Server
 


startup = (assemblyJarPath, scalaCompilerJars, serverFlags = "", pidcallback) ->
  classpath = assemblyJarPath + path.delimiter + scalaCompilerJars
  
