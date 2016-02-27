# Download and startup of ensime server
fs = require 'fs'
path = require 'path'
_ = require 'lodash'

{packageDir, withSbt, mkClasspathFileName} = require('./utils')
{parseDotEnsime} = require './ensime-client/dotensime-utils'
doStartEnsimeServer = require './ensime-client/ensime-server-startup'
{updateEnsimeServer} = require './ensime-server-update'
updateEnsimeServerWithCoursier = require './ensime-server-update-coursier'
log = require('loglevel').getLogger('ensime.startup')
###
## Pseudo:
This code is pretty complex with lots of continuation passing.
Here is some kind of pseudo for easier understanding:

startClient(dotEnsime) ->
  if(serverRunning(dotEnsime))
    doStartClient(dotEnsime)
  else
    startServer(dotEnsime, () ->
      doStartClient(dotEnsime)
    )

startServer(dotEnsime, whenStarted) ->
  if(classpathOk(dotEnsime))
    doStartServer(dotEnsime, whenStarted)
  else
    updateServer(dotEnsime, () ->
      doStartServer(dotEnsime, whenStarted)
    )

###

# ensime server version from settings
ensimeServerVersion = ->
  atom.config.get('Ensime.ensimeServerVersion')



# Check that we have a classpath that is newer than atom
# ensime package.json (updated on release), otherwise delete it
classpathFileOk = (cpF) ->
  if not fs.existsSync(cpF)
    false
  else
    cpFStats = fs.statSync(cpF)
    fine = cpFStats.isFile && cpFStats.ctime > fs.statSync(packageDir() + path.sep + 'package.json').mtime
    if not fine
      fs.unlinkSync(cpF)
    fine


# Start ensime server. If classpath file is out of date, make an update first
startEnsimeServer = (parsedDotEnsime, pidCallback) ->
  if not fs.existsSync(parsedDotEnsime.cacheDir)
    fs.mkdirSync(parsedDotEnsime.cacheDir)

  ensimeServerFlags = atom.config.get('Ensime.ensimeServerFlags')
  
  # update server and start
  if atom.config.get('Ensime.useCoursierToBootstrapServer')
    # Pull out so coursier can have different classpath file name
    cpF = mkClasspathFileName(parsedDotEnsime.scalaVersion, ensimeServerVersion())
    log.trace("classpathfile name: #{cpF}")
    if(not classpathFileOk(cpF))
      updateEnsimeServerWithCoursier(parsedDotEnsime, ensimeServerVersion(), cpF,
        () -> doStartEnsimeServer(cpF, parsedDotEnsime, pidCallback, ensimeServerFlags))
    else
      doStartEnsimeServer(cpF, parsedDotEnsime, pidCallback, ensimeServerFlags)
  else
    cpF = mkClasspathFileName(parsedDotEnsime.scalaVersion, ensimeServerVersion())
    if(not classpathFileOk(cpF))
      withSbt (sbtCmd) ->
        updateEnsimeServer(sbtCmd, parsedDotEnsime.scalaVersion, ensimeServerVersion(),
          () -> doStartEnsimeServer(cpF, parsedDotEnsime, pidCallback, ensimeServerFlags))
    else
      doStartEnsimeServer(cpF, parsedDotEnsime, pidCallback, ensimeServerFlags)



module.exports = {
  startClient: (require './ensime-client/ensime-client-startup')(startEnsimeServer)
}
