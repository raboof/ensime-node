const fs = require('fs-extra');
import * as path from 'path';
import * as temp from 'temp';
import {ServerConnection} from './server-connection'
import * as Promise from 'bluebird'
import {Typehinted, SymbolInfo, CompletionsResponse, RefactoringDesc, Point} from './server-protocol'

temp.track()
const tempDir = temp.mkdirSync('ensime-temp-files');
const getTempDir = () => tempDir

const getTempPath = (file) => {
  if(process.platform == 'win32')
    return path.join(getTempDir(), file.replace(':', ""))
  else
    return path.join(getTempDir(), file)
}

const withTempFile = (filePath: string, bufferText: string) : PromiseLike<string> => {
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
    function getCompletions(filePath: string, bufferText: string, offset: number, noOfAutocompleteSuggestions: number) {
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

    function getSymbolAtPoint(path: string, offset) : PromiseLike<Typehinted> {
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

    function getDocUriAtPoint(file: string, point: Point) {
        return client.post({
            typehint: "DocUriAtPointReq",
            file: file,
            point: point
        });
    }

    function getImportSuggestions(file: string, characterIndex: number, symbol: string) {
        return client.post({
            typehint: 'ImportSuggestionsReq',
            file: file,
            point: characterIndex,
            names: [symbol],
            maxResults: 10
        });
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
        searchPublicSymbols,
        getDocUriAtPoint,
        getImportSuggestions
    }
}



export interface Api {
    getCompletions: (filePath: string, bufferText: any, offset: any, noOfAutocompleteSuggestions: any) => PromiseLike<CompletionsResponse>;
    getSymbolAtPoint: (path: string, offset: any) => PromiseLike<SymbolInfo>;
    typecheckFile: (path: string) => PromiseLike<Typehinted>;
    typecheckBuffer: (path: string, text: string) => void;
    symbolByName: (qualifiedName: any) => PromiseLike<Typehinted>;
    formatSourceFile: (path: any, contents: any, callback: any) => PromiseLike<Typehinted>;
    getImplicitInfo: (path: string, startO: number, endO: number) => PromiseLike<Typehinted>;
    typecheckAll(): void;
    unloadAll(): void;
    getRefactoringPatch: (procId: number, refactoring: RefactoringDesc) => PromiseLike<Typehinted>;
    searchPublicSymbols(keywords: string[], maxSymbols: number): PromiseLike<Typehinted>;
    getDocUriAtPoint(file: string, point: Point): PromiseLike<Typehinted>;
    getImportSuggestions(file: string, characterIndex: number, symbol: string): PromiseLike<Typehinted>;
}
