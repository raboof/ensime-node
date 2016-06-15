import {DotEnsime} from '../types'
import {ServerConnection} from '../server-api/server-connection'
import {Api, apiOf} from '../server-api/server-api'
import * as _ from 'lodash'
import * as path from 'path'

export interface EnsimeInstance {
    destroy() : any;
    rootDir: string;
    api: Api;
    dotEnsime: DotEnsime;
    isSourceOf(path: string): boolean
}

export function makeInstanceOf(dotEnsime: DotEnsime, connection: ServerConnection, ui?: {destroy: () => any}) : EnsimeInstance{
    function destroy () {
        this.connection.destroy()
        if(this.ui) {
            this.ui.destroy()
        } 
    } 
    
    const isSourceOf = (path: string) => _.some(dotEnsime.sourceRoots, (sourceRoot) => _.startsWith(path, sourceRoot))    

    return {
        rootDir: dotEnsime.rootDir,
        api: apiOf(connection),
        destroy,
        isSourceOf,
        dotEnsime
    } 
        
}