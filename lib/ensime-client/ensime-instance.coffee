_ = require 'lodash'

module.exports = (dotEnsime, client, ui) ->
  {
    rootDir: dotEnsime.rootDir
    dotEnsime: dotEnsime
    client: client
    ui: ui # client ui with a destroy cleanup function to call on termination
    #statusbarView: statusbarView
    #typechecking: typechecking
    
    destroy: () ->
      client.destroy()
      ui?.destroy()
    isSourceOf: (path) -> _.some(dotEnsime.sourceRoots, (sourceRoot) -> path.startsWith(sourceRoot))
  }
