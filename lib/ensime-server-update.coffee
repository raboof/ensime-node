{packageDir, mkClasspathFileName} = require './utils'
EnsimeServerUpdateLogView = require './views/ensime-server-update-log-view'
{spawn} = require('child_process')
fs = require('fs')
path = require('path')
log = require('loglevel').getLogger('ensime.server-update')

createSbtClasspathBuild = (scalaVersion, ensimeServerVersion, classpathFile) ->
  """
  import sbt._
  import IO._
  import java.io._

  scalaVersion := \"#{scalaVersion}\"

  ivyScala := ivyScala.value map { _.copy(overrideScalaVersion = true) }

  // we don't need jcenter, so this speeds up resolution
  fullResolvers -= Resolver.jcenterRepo

  // allows local builds of scala
  resolvers += Resolver.mavenLocal

  // for java support
  resolvers += \"NetBeans\" at \"http://bits.netbeans.org/nexus/content/groups/netbeans\"

  // this is where the ensime-server snapshots are hosted
  resolvers += Resolver.sonatypeRepo(\"snapshots\")

  libraryDependencies ++= Seq(
    \"org.ensime\" %% \"ensime\" % \"#{ensimeServerVersion}\"
  )

  dependencyOverrides ++= Set(
    \"org.scala-lang\" % \"scala-compiler\" % scalaVersion.value,
    \"org.scala-lang\" % \"scala-library\" % scalaVersion.value,
    \"org.scala-lang\" % \"scala-reflect\" % scalaVersion.value,
    \"org.scala-lang\" % \"scalap\" % scalaVersion.value
  )

  val saveClasspathTask = TaskKey[Unit](\"saveClasspath\", \"Save the classpath to a file\")

  saveClasspathTask := {
    val managed = (managedClasspath in Runtime).value.map(_.data.getAbsolutePath)
    val unmanaged = (unmanagedClasspath in Runtime).value.map(_.data.getAbsolutePath)
    val out = file(\"""#{classpathFile}\""")
    IO.write(out, (unmanaged ++ managed).mkString(File.pathSeparator))
  }
  """


  # Updates ensime server, invoke callback when done
updateEnsimeServer = (sbtCmd, scalaVersion, ensimeServerVersion, whenUpdated = () -> ) ->
  tempdir =  packageDir() + path.sep + "ensime_update_"

  @serverUpdateLog = new EnsimeServerUpdateLogView()

  pane = atom.workspace.getActivePane()
  pane.addItem @serverUpdateLog
  pane.activateItem @serverUpdateLog

  if not fs.existsSync(tempdir)
    fs.mkdirSync(tempdir)
    fs.mkdirSync(tempdir + path.sep + 'project')

  # write out a build.sbt in this dir
  fs.writeFileSync(tempdir + path.sep + 'build.sbt', createSbtClasspathBuild(scalaVersion, ensimeServerVersion,
    mkClasspathFileName(scalaVersion, ensimeServerVersion)))

  fs.writeFileSync(tempdir + path.sep + 'project' + path.sep + 'build.properties', 'sbt.version=0.13.9\n')

  # run sbt "saveClasspath" "clean"
  pid = spawn("#{sbtCmd}", ['-Dsbt.log.noformat=true', 'saveClasspath', 'clean'], {cwd: tempdir})
  pid.stdout.on 'data', (chunk) -> log.trace(chunk.toString('utf8'))
  pid.stderr.on 'data', (chunk) -> log.trace(chunk.toString('utf8'))
  pid.stdout.on 'data', (chunk) => @serverUpdateLog.addRow(chunk.toString('utf8'))
  pid.stderr.on 'data', (chunk) => @serverUpdateLog.addRow(chunk.toString('utf8'))
  pid.stdin.end()
  pid.on 'close', (exitCode) ->
    if(exitCode == 0)
      whenUpdated()
    else
      atom.notifications.addError("Ensime server update failed", {
        dismissable: true
        detail: "Exit code: " + exitCode
      })
      



module.exports = {
  updateEnsimeServer
}
