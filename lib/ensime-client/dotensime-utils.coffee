fs = require ('fs')
lisp = require ('./lisp/lisp')
{sexpToJObject} = require './lisp/swank-extras'

readDotEnsime = (path) ->
  raw = fs.readFileSync(path)
  rows = raw.toString().split(/\r?\n/);
  filtered = rows.filter (l) -> l.indexOf(';;') != 0
  filtered.join('\n')

parseDotEnsime = (path) ->
  # scala version from .ensime config file of project
  dotEnsime = readDotEnsime(path)
  dotEnsimeLisp = lisp.readFromString(dotEnsime)
  dotEnsimeJs = sexpToJObject(dotEnsimeLisp)
  {
    name: dotEnsimeJs[':name']
    scalaVersion: dotEnsimeJs[':scala-version']
    javaHome: dotEnsimeJs[':java-home']
    javaFlags: dotEnsimeJs[':java-flags']
    rootDir: dotEnsimeJs[':root-dir']
    cacheDir: dotEnsimeJs[':cache-dir']
    dotEnsimePath: path
  }

module.exports = {
  parseDotEnsime
}
