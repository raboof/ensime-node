path = require 'path'
_ = require 'lodash'
{fixClasspath, javaArgsOf, javaCmdOf} = require '../lib/server-startup-utils'

describe 'server-startup', ->
  describe 'fixClasspath', ->
    it "should correctly sort classpath and add tools.jar", ->
      javaHome = '__javaHome__'
      classpathList = ['a.jar', 'b.jar', 'monkey.jar']
      fixedClasspath = fixClasspath(javaHome, classpathList)
      expect(fixedClasspath).toBe(_.join(['monkey.jar','a.jar','b.jar',path.join('__javaHome__','lib','tools.jar')], path.delimiter))
  
  describe 'javaArgsOf', ->
    it "should work without server flags", ->
      args = javaArgsOf('monkey.jar:a.jar:b.jar:__javaHome__/lib/tools.jar', '__.ensime__')
      expect(args).toEqual [ '-classpath', 'monkey.jar:a.jar:b.jar:__javaHome__/lib/tools.jar',
       '-Densime.config=__.ensime__', '-Densime.protocol=jerk', 'org.ensime.server.Server' ]
  
    it "should work without with server flags", ->
      args = javaArgsOf('monkey.jar:a.jar:b.jar:__javaHome__/lib/tools.jar', '__.ensime__',
        '-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=11111')
      expect(args).toEqual [ '-classpath', 'monkey.jar:a.jar:b.jar:__javaHome__/lib/tools.jar',
       '-Densime.config=__.ensime__', '-Densime.protocol=jerk', '-Xdebug
        -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=11111', 'org.ensime.server.Server' ]

  describe 'javaCmdOf', ->
    it 'should find java form .ensime', ->
      dotEnsime =
        javaHome: '__javaHome__'
      expect(javaCmdOf(dotEnsime)).toBe path.join('__javaHome__','bin','java')
