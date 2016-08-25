import _ = require('lodash');
import * as Promise from 'bluebird';
import {ChildProcess} from 'child_process';
export type pid = string
export import serverProtocol = require('./server-api/server-protocol')
import {apiOf} from './server-api/server-api'

import {ServerConnection} from './server-api/server-connection'

export interface ServerStarter {
    (project: DotEnsime): PromiseLike<ChildProcess>
} 

export interface ServerSettings {
    persistentFileArea: string
    notifier? : () => any
    serverVersion? : string
}

export interface DotEnsime {
    name: string
    scalaVersion: string
    scalaEdition: string
    javaHome: string
    javaFlags: string
    rootDir: string
    cacheDir: string
    compilerJars: string
    dotEnsimePath: string
    sourceRoots: [string]
}