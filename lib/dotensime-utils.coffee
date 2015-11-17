require ('fs')

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
    scalaVersion: dotEnsimeJs[':scala-version']
    javaHome: dotEnsimeJs[':java-home']
  }

module.exports = {
  parseDotEnsime
}
