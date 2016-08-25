import * as net from 'net';
import * as path from 'path';
import * as loglevel from 'loglevel';
const log = loglevel.getLogger('ensime.client')
import * as Promise from 'bluebird'
import {WebsocketClient} from '../network/NetworkClient'
import {Typehinted} from '../server-api/server-protocol'


/**
 * A running and connected ensime client
 * 
 * low-level api
 */
export interface ServerConnection {
    destroy: () => void
    
    httpPort: string
    /**
     * Post a msg object 
     */
    post: (msg: any) => PromiseLike<Typehinted>
}

export function createConnection(httpPort: string, generalMsgHandler, serverPid = undefined): PromiseLike<ServerConnection> {
    const deferredConnection = Promise.defer<ServerConnection>();

    const callbackMap : {[callId: string]: Promise.Resolver<any>} = { }
    let ensimeMessageCounter = 1
    
    function handleIncoming(msg) {
      const json = JSON.parse(msg);
      log.debug("incoming: ", json)
      const callId = json.callId
      // If RpcResponse - lookup in map, otherwise use some general function for handling general msgs

      if(callId) {
        try {
          const p = callbackMap[callId];
          log.debug("resolving promise: " + p)
          p.resolve(json.payload)
        } catch(error) {
          log.trace(`error in callback: ${error}`)
        } finally {
          delete callbackMap[callId]
        }
      } else {
        return generalMsgHandler(json.payload)
      }
    }
    
    function onConnect() {
      deferredConnection.resolve(publicApi());
    } 


    function publicApi() : ServerConnection {
      log.debug("creating client api");
      return {
        post,
        destroy,
        httpPort
      }
    } 

    const netClient = new WebsocketClient(httpPort, onConnect, handleIncoming)

    /**
     * Kills server if it was spawned from here.
     */
    function destroy() {
      netClient.destroy();
      if(serverPid)
        serverPid.kill();
    }
    
    function postString(msg): PromiseLike<Typehinted> {
      const p = Promise.defer<Typehinted>();
      const wireMsg = `{"req": ${msg}, "callId": ${ensimeMessageCounter}}`
      callbackMap[ensimeMessageCounter++] = p
      log.debug("outgoing: " + wireMsg)
      netClient.send(wireMsg)
      return p.promise;
    }

    
    function post(msg) : PromiseLike<Typehinted> {
      return postString(JSON.stringify(msg))
    }

    return deferredConnection.promise;
}
