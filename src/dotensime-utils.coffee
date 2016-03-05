fs = require ('fs')
lisp = require ('./lisp/lisp')
{sexpToJObject} = require './lisp/swank-extras'
_ = require 'lodash'
Promise = require 'bluebird'
glob = require 'glob'


readDotEnsime = (path) ->
  raw = fs.readFileSync(path)
  rows = raw.toString().split(/\r?\n/)
  filtered = rows.filter (l) -> l.indexOf(';;') != 0
  filtered.join('\n')

parseDotEnsime = (path) ->
  # scala version from .ensime config file of project
  dotEnsime = readDotEnsime(path)
  dotEnsimeLisp = lisp.readFromString(dotEnsime)
  dotEnsimeJs = sexpToJObject(dotEnsimeLisp)
  subprojects = dotEnsimeJs[':subprojects']
  sourceRoots = _.flattenDeep(_.map(subprojects, (sp) -> sp[':source-roots']))
  scalaVersion = dotEnsimeJs[':scala-version']
  scalaEdition = scalaVersion.substring(0, 4)

  {
    name: dotEnsimeJs[':name']
    scalaVersion: scalaVersion
    scalaEdition: scalaEdition
    javaHome: dotEnsimeJs[':java-home']
    javaFlags: dotEnsimeJs[':java-flags']
    rootDir: dotEnsimeJs[':root-dir']
    cacheDir: dotEnsimeJs[':cache-dir']
    compilerJars: dotEnsimeJs[':scala-compiler-jars']
    dotEnsimePath: path
    sourceRoots: sourceRoots
  }

# Gives promise of .ensime paths
allDotEnsimesInPaths = (paths) ->
  globTask = Promise.promisify(glob)
  promises = dirs.map (dir) ->
    globTask(
      '.ensime'
        cwd: dir
        matchBase: true
        nodir: true
        realpath: true
        ignore: '**/{node_modules,.ensime_cache,.git,target,.idea}/**'
    )
  promise = Promise.all(promises)
  promise.then (dotEnsimesUnflattened) ->
    {path: path} for path in _.flattenDeep(dotEnsimesUnflattened)
  

dotEnsimesFilter = (path, stats) ->
  !stats.isDirectory() && ! path.endsWith('.ensime')

module.exports = {
  parseDotEnsime
  dotEnsimesFilter
  allDotEnsimesInPaths
}
