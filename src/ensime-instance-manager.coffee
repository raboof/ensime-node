# Takes care of mapping project roots to Ensime clients for multiple Ensime project support under same Atom window
# TODO: Should use sourdeDirs of .ensime to do mapping of files -> ensime instance

_ = require 'lodash'
path = require 'path'

module.exports = class InstanceManager

  constructor: ->
    @instances = []

  # Just something with a rootDir for now
  registerInstance: (instance) ->
    @instances.push(instance)

  stopInstance: (dotEnsime) ->
    for instance in @instances when instance.rootDir == dotEnsime.rootDir
      do (instance) =>
        instance.destroy()
        @instances = _.without(@instances, instance)

  # optional running ensime client of scala source path O(n)
  instanceOfFile: (path) ->
    _.find(@instances, (instance) ->
      path.startsWith(instance.dotEnsime.cacheDir) or instance.isSourceOf(path)
    )

  destroyAll: ->
    _.forEach(@instances, (instance) ->
      instance.destroy()
    )

  firstInstance: ->
    @instances[0]

  isStarted: (dotEnsimePath) ->
    _.some(@instances, (instance) -> instance.dotEnsime.dotEnsimePath == dotEnsimePath)
