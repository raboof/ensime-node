
_ = require 'lodash'

module.exports = (dotEnsime, client, statusbarView, typechecking) ->
  {
    rootDir: dotEnsime.rootDir
    dotEnsime: dotEnsime
    client: client
    statusbarView: statusbarView
    typechecking: typechecking
    destroy: () ->
      client.destroy()
      statusbarView.destroy()
      typechecking?.destroy()
    isSourceOf: (path) -> _.some(dotEnsime.sourceRoots, (sourceRoot) -> path.startsWith(sourceRoot))
  }
