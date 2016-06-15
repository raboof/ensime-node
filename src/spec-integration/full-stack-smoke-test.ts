import fs = require('fs')
import * as path from 'path';
import {writeFile, readFile} from '../lib/file-utils';

import temp = require('temp');

import loglevel = require('loglevel');
import Promise = require('bluebird');
import {spawn} from 'child_process';
import {DotEnsime, ServerStarter, pid, clientStarterFromServerStarter, startServerFromAssemblyJar, dotEnsimeUtils} from '../lib/index'
import {ServerConnection} from '../lib/server-api/server-connection'

const log = loglevel.getLogger('full-stack-smoke');

fdescribe("full-stack-smoke", () => {
    let projectPath: string  = undefined;
    
    let originalTimeout = jasmine.DEFAULT_TIMEOUT_INTERVAL;   
    jasmine.DEFAULT_TIMEOUT_INTERVAL = 120000
    let client : ServerConnection = undefined

    beforeAll((done) => {
        jasmine.DEFAULT_TIMEOUT_INTERVAL = 120000
        // temp.track();
        originalTimeout = jasmine.DEFAULT_TIMEOUT_INTERVAL
        projectPath = temp.mkdirSync('ensime-integration-test');
        generateProject(projectPath).then(() => {
            fs.exists(path.join(projectPath, "build.sbt"), (buildDotSbtExists) => {
                expect(buildDotSbtExists);
                genDotEnsime(projectPath).then((exitCode) => {
                    expect(exitCode).toBe(0);
                    
                    const dotEnsimePath = path.join(projectPath, ".ensime"); 
                    fs.exists(dotEnsimePath, (dotEnsimeExists) => {
                        expect(dotEnsimeExists);
                    });
                    
                    startEnsime(dotEnsimePath).then((c) => {
                        log.debug('got a connected client', c);
                        client = c;
                        done();
                    }); 

                });
            });
        }); 
    });

    afterAll((done) => {
        jasmine.DEFAULT_TIMEOUT_INTERVAL = originalTimeout;
        client.destroy();
        // temp.cleanupSync();
        fs.exists(projectPath, (exists) => {
            // expect(exists).toBeFalsy();
            done();
        });
    });

    /**
     * Generates project structure and build.sbt
     */    
    const generateProject = (dir: string) => {
        fs.mkdirSync(path.join(dir, 'src'));
        fs.mkdirSync(path.join(dir, 'src', 'main'));
        fs.mkdirSync(path.join(dir, 'src', 'main', 'scala'));

        const buildDotSbt = `
            lazy val commonSettings = Seq(
                organization := "org.ensime",
                version := "0.1-SNAPSHOT",
                scalaVersion := "2.11.8"
            )

            lazy val root = (project in file(".")).
                settings(commonSettings: _*).
                settings(
                    name := "ensime-test-project"
                )
        `;
        

        // http://stackoverflow.com/questions/37833355/how-to-specify-which-overloaded-function-i-want-in-typescript/37835265#37835265


        return writeFile(path.join(dir, "build.sbt"), buildDotSbt);        
    };

    /**
     * Calls sbt gen-ensime to generate .ensime
     */
    const genDotEnsime = (dir: string) => {
        const pid = spawn("sbt", ["gen-ensime"], {cwd: dir});
        const p = Promise.defer<number>();

        pid.stdin.end();
        
        pid.stdout.on('data', (chunk) => {
            log.info('gen-ensime', chunk.toString('utf8'))
        })

        pid.on('close', (exitCode: number) => {
           p.resolve(exitCode);
        });
        return p.promise; 
    };

    function startEnsime(dotEnsimePath: string): Promise<ServerConnection> {
        return dotEnsimeUtils.parseDotEnsime(dotEnsimePath).then((dotEnsime) => {
            log.debug("got a parsed .ensime")
            const serverStarter : ServerStarter = (project: DotEnsime) => {
                // FIXME: assembly jar location in docker image?
                const assemblyJar = "/Users/viktor/dev/projects/atom-ensime/ensime_2.11-1.0.0-SNAPSHOT-assembly.jar"
                const process = startServerFromAssemblyJar(assemblyJar, project)
                return Promise.resolve(process)
            } 
            return clientStarterFromServerStarter(serverStarter)(dotEnsime, (msg) => {
                log.debug(msg);
            });
        });
    }
    
    it("should get connection info", (done) => {
        const fooDotScala = path.join(projectPath, "src", "main", "scala", "Foo.scala")
        const content = `
            object Foo {
                def bar = "baz";
            }
        `;
        writeFile(fooDotScala, content);
        client.post({"typehint":"ConnectionInfoReq"}).then((res) => {
            log.debug("got an answer: ", res)
            // client.typecheckFile(fooDotScala);
            // client.typecheckBuffer(fooDotScala, content, (res) => {
            //     log.debug("got an answer: ", res)
            // });
            done();
        });
    });
});