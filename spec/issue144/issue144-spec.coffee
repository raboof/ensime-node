fs = require 'fs'
path = require 'path'
{getTempDir} = require '../../lib/utils'

describe 'mkdirSync should really be sync?', ->
  tempdir =  getTempDir() + path.sep
  
  it "should not blow with ENOENT: no such file or directory", ->
    if not fs.existsSync(tempdir)
      fs.mkdirSync(tempdir)
    
    inner = tempdir + path.sep + 'inner'
    if not fs.existsSync(inner)
      fs.mkdirSync(inner)

    fs.writeFileSync(tempdir + path.sep + 'foo', 'foo content')
    fs.writeFileSync(tempdir + path.sep + 'inner' + path.sep + 'bar', 'bar content')
