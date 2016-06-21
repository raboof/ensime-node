import {DotEnsime} from '../types'
import {ServerConnection} from '../server-api/server-connection'
import {Api, apiOf} from '../server-api/server-api'
import * as _ from 'lodash'
import * as path from 'path'


export interface EnsimeInstance<UI> {
    destroy() : any;
    rootDir: string;
    api: Api;
    dotEnsime: DotEnsime;
    isSourceOf(path: string): boolean;
    
    /** Client specific ui to use for ui switching and stuff */
    ui: UI
}

export function makeInstanceOf<T extends {destroy(): void}>(dotEnsime: DotEnsime, connection: ServerConnection, ui: T) : EnsimeInstance<T>{
    function destroy () {
        connection.destroy()
        if(ui) {
            ui.destroy()
        } 
    } 
    
    const isSourceOf = (path: string) => _.some(dotEnsime.sourceRoots, (sourceRoot) => _.startsWith(path, sourceRoot))    

    return {
        rootDir: dotEnsime.rootDir,
        api: apiOf(connection),
        destroy,
        isSourceOf,
        dotEnsime,
        ui
    } 
        
}