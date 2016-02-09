fs = require 'fs'
path = require 'path'

describe 'mkdirSync should really be sync?', ->
  
  tempdir =  "/tmp/blahablaha"
  
  it "should not blow with ENOENT: no such file or directory", ->
    if not fs.existsSync(tempdir)
      fs.mkdirSync(tempdir)
      fs.mkdirSync(tempdir + path.sep + 'inner')

    fs.writeFileSync(tempdir + path.sep + 'foo', 'foo content')
    fs.writeFileSync(tempdir + path.sep + 'inner' + path.sep + 'bar', 'bar content')
