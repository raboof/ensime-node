temp = (require 'temp').track()

path = require 'path'
fs = require 'fs'

loglevel = require 'loglevel'
loglevel.setDefaultLevel('trace')
loglevel.setLevel('trace')
log = loglevel.getLogger('ensime-cloent-startup-spec')

chokidar = require 'chokidar'

testFile = (expectedFile) ->
  spy = jasmine.createSpy('callback')
  
  watcher = chokidar.watch(expectedFile, {
    persistent: true
    }).on('add', (path) ->
      spy()
      watcher.close()
      )
      
  fs.writeFileSync(expectedFile, 'Hello Gaze, see me!')
  
  waitsFor( (-> spy.callCount > 0), "callback wasn't called in time", 5000)



xdescribe 'chokidar', ->
  it "should notice absolute paths, even from temp", ->
    testFile(temp.path({suffix: '.txt'}))

  it "should notice absolute paths if relativized", ->
    testFile(path.join process.cwd(), 'foo')
  
