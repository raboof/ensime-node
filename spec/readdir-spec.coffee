recread = require 'recursive-readdir'
process = require 'process'
path = require 'path'


describe 'read-dir depdendency should work', ->
  modulePath = path.dirname(module.filename)
  root = __dirname + path.sep + "testdata"

  it "should work with another non-buggy version?", ->
    dotEnsimesFilter = (path, stats) ->
      stats.isFile() && ! path.endsWith('.ensime')

    recread(root, [], (err, files) ->
      )
