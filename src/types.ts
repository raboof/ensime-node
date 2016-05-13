import _ = require('lodash');

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

export class EnsimeInstance {
    rootDir: string;
    
    constructor(public dotEnsime: DotEnsime, public client: any, public ui?: any) {
        this.rootDir = dotEnsime.rootDir;
    }
    
    isSourceOf = (path) => _.some(this.dotEnsime.sourceRoots, (sourceRoot) => path.startsWith(sourceRoot))    
    
    destroy () {
        this.client.destroy()
        if(this.ui) {
            this.ui.destroy()
        } 
    } 
        
}
