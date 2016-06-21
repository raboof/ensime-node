import * as _  from 'lodash'
import * as path from 'path'
import {DotEnsime} from '../types'
import {EnsimeInstance} from './instance'
/**
 * Takes care of mapping project roots to Ensime clients for multiple Ensime project support under same Atom window
 * This might be supported in vscode too, but currently isn't
 * # TODO: Should use sourdeDirs of .ensime to do mapping of files -> ensime instance
 */
export class InstanceManager<T> {

  instances: EnsimeInstance<T>[]

  constructor() {
      this.instances = []
  }
  
  registerInstance(instance: EnsimeInstance<T>) {
      this.instances.push(instance)
  }

  stopInstance(dotEnsime: DotEnsime) {
    for (let instance of this.instances) {
      if(instance.rootDir == dotEnsime.rootDir) {
        instance.destroy()
        this.instances = _.without(this.instances, instance)
      }
    } 
  }

  // optional running ensime client of scala source path O(n)
  instanceOfFile(path: string) {
    return _.find(this.instances, (instance) =>
      _.startsWith(path, instance.dotEnsime.cacheDir) || instance.isSourceOf(path)
    )
  }

  destroyAll() {
    _.forEach(this.instances, (instance) => instance.destroy())
  }

  firstInstance() {
    return this.instances[0]
  }

  isStarted(dotEnsimePath: string) {
    return _.some(this.instances, (instance) => instance.dotEnsime.dotEnsimePath == dotEnsimePath)
  }

}