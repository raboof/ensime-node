// http://stackoverflow.com/questions/30712638/typescript-export-imported-interface

export const Client = require('./client');
export const InstanceManager = require('./ensime-instance-manager');

export { DotEnsime, EnsimeInstance as Instance} from './types';

export import formatting = require('./formatting');
export {default as ensimeServerUpdate} from './ensime-server-update-coursier';
export import dotEnsimeUtils = require('./dotensime-utils');
export import ensimeServerStartup = require('./ensime-server-startup');
export * from './ensime-client-startup';

export const startServerFromAssemblyJar = ensimeServerStartup.startServerFromAssemblyJar;
export const startServerFromFile = ensimeServerStartup.startServerFromFile;
export {default as ensimeClientStartup} from './ensime-client-startup';
  
