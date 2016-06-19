const fs = require('fs-extra');
import * as path from 'path';
import * as temp from 'temp';
import {ServerConnection} from './server-connection'
import * as Promise from 'bluebird'
import {Typehinted, RefactoringDesc} from './server-protocol'

temp.track()
const tempDir = temp.mkdirSync('ensime-temp-files');
const getTempDir = () => tempDir

const getTempPath = (file) => {
  if(process.platform == 'win32')
    return path.join(getTempDir(), file.replace(':', ""))
  else
    return path.join(getTempDir(), file)
}

const withTempFile = (filePath: string, bufferText: string) : Promise<string> => {
    const tempFilePath = getTempPath(filePath);
    const p = Promise.defer<string>();
    fs.outputFile(tempFilePath, bufferText, (err) => {
        if (err)
            p.reject("error with file");
        else 
            p.resolve(tempFilePath);
    });
    return p.promise; 
} 


export function apiOf(client: ServerConnection): Api {
    function getCompletions(filePath: string, bufferText, offset, noOfAutocompleteSuggestions) {
        return withTempFile(filePath, bufferText).then((tempFile) => {
            const msg = {
                typehint: "CompletionsReq",
                fileInfo: {
                    file: filePath,
                    contentsIn: tempFile
                },
                point: offset,
                maxResults: noOfAutocompleteSuggestions,
                caseSens: false,
                reload: true
            }
            return client.post(msg);
        });
    } 

    function getSymbolAtPoint(path: string, offset) : Promise<Typehinted> {
        return new Promise<Typehinted>((resolve, reject) => {
            const req = {
                typehint: "SymbolAtPointReq",
                file: path,
                point: offset
            }
            client.post(req).then((msg) => {
                if(msg.typehint == 'SymbolInfo') 
                    resolve(msg);
                else
                    reject("no symbol response");
            });
        });
    }
        
    function typecheckBuffer(path: string, text: string) {
        withTempFile(path, text).then((tempFilePath) => {
            const msg = {
                typehint: "TypecheckFileReq",
                fileInfo: {
                    file: path,
                    contentsIn: tempFilePath
                }
            }
            return client.post(msg);
        });
    } 

    function typecheckFile(path: string) {
        const msg = {
            typehint: "TypecheckFileReq",
            fileInfo: {
                file: path
            }
        }
        return client.post(msg);
    } 

    function symbolByName(qualifiedName) {
        const msg = {
            typehint: 'SymbolByNameReq',
            typeFullName: qualifiedName
        }
        return client.post(msg);
    }
        
    function formatSourceFile(path, contents, callback) {
        return withTempFile(path, contents).then((tempFilePath) => {
            const req = {
                typehint: "FormatOneSourceReq",
                file: {
                    file: path,
                    contentsIn: tempFilePath
                }
            }
            return client.post(req);
        });
    }


    function getImplicitInfo(path: string, startO: number, endO: number) {
        const msg = {
            "typehint":"ImplicitInfoReq",
            "file": path,
            "range": {
                "from": startO,
                "to": endO
            }
        }
        return client.post(msg)
    }


    function typecheckAll() {
        client.post({"typehint": "TypecheckAllReq"});
    }

    function unloadAll() {
        client.post({"typehint": "UnloadAllReq"});
    }

    function getRefactoringPatch(procId: number, refactoring: RefactoringDesc) {
        const req = {
            typehint: 'RefactorReq',
            procId: procId,
            params: refactoring,
            interactive: false
        }
        return client.post(req);
    }

    function searchPublicSymbols(keywords: string[], maxSymbols: number) {
        return client.post({
            typehint: "PublicSymbolSearchReq",
            keywords: keywords,
            maxResults: maxSymbols
        })
    }

    return {
        getCompletions,
        getSymbolAtPoint,
        typecheckFile,
        typecheckBuffer,
        symbolByName,
        formatSourceFile,
        getImplicitInfo,
        typecheckAll,
        unloadAll,
        getRefactoringPatch,
        searchPublicSymbols
    }
}

export interface Api {
    getCompletions: (filePath: string, bufferText: any, offset: any, noOfAutocompleteSuggestions: any) => Promise<Typehinted>;
    getSymbolAtPoint: (path: string, offset: any) => Promise<Typehinted>;
    typecheckFile: (path: string) => Promise<Typehinted>;
    typecheckBuffer: (path: string, text: string) => void;
    symbolByName: (qualifiedName: any) => Promise<Typehinted>;
    formatSourceFile: (path: any, contents: any, callback: any) => Promise<Typehinted>;
    getImplicitInfo: (path: string, startO: number, endO: number) => Promise<Typehinted>;
    typecheckAll(): void;
    unloadAll(): void;
    getRefactoringPatch: (procId: number, refactoring: RefactoringDesc) => Promise<Typehinted>;
    searchPublicSymbols(keywords: string[], maxSymbols: number): Promise<Typehinted>;

}
