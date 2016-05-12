updateEnsimeServer = (require('../lib/ensime-server-update-coursier')).default
fs = require 'fs'
path = require 'path'
temp = require 'temp'

loglevel = require 'loglevel'
loglevel.setDefaultLevel('trace')
loglevel.setLevel('trace')

log = loglevel.getLogger('ensime-server-update-coursier-spec')

describe "ensime-server-update", ->
  beforeEach ->

  it "should be able to download coursier", ->
    
    
    # Java is installed installed on appveyor build servers C:\Program Files\Java\jdk1.8.0
    # http://www.appveyor.com/docs/installed-software#java
    tempDir = temp.mkdirSync('ensime-integration-test')
    
    dotEnsime =
      name: "test"
      scalaVersion: "2.11.8"
      scalaEdition: "2.11"
      rootDir: tempDir
      cacheDir: tempDir + path.sep + ".ensime_cache"
      dotEnsimePath: tempDir + path.sep + ".ensime"

    spy = jasmine.createSpy('classpathfile-callback')
      
    getPidLogger = ->
      (pid) ->
        pid.stdout.on 'data', (chunk) -> log.info chunk.toString 'utf8'
        pid.stderr.on 'data', (chunk) -> log.info chunk.toString 'utf8'
      
    failure = (msg, code) -> log.error(msg, code)
  
    log.error('doing ensime server update using coursier')
    doUpdateServer = updateEnsimeServer(tempDir, getPidLogger, failure)
    
    
    
    log.error('updater created')
    # function doUpdateServer(parsedDotEnsime: DotEnsime, ensimeServerVersion: string, classpathFile: string, whenUpdated: () => void ) {
    doUpdateServer(dotEnsime, "0.9.10-SNAPSHOT", path.join(tempDir, "classpathfile"), spy)
    log.trace('ran doUpdateServer')
    
    waitsFor( (-> spy.callCount > 0), "callback wasn't called in time", 120000)
    # runs ->
#      expect(spy.mostRecentCall.args).toEqual exp
#      expect(spy).toHaveBeenCalledWith(null, ['example.coffee'])

  afterEach ->
    temp.cleanupSync()
