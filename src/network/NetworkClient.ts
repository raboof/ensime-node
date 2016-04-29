import loglevel = require('loglevel');
const WebSocket = require("ws");


export interface NetworkClient {
    destroy(): any
}

export class TcpClient implements NetworkClient {
    destroy() {
    }
}
 
export class WebsocketClient implements NetworkClient {
    websocket: any;
    log = loglevel.getLogger('ensime.socketclient')
    
    constructor(httpPort: string, onConnected: () => any, onMsg: (msg: string) => any) {
        this.websocket = new WebSocket("ws://localhost:" + httpPort + "/jerky");
    
        this.websocket.on("open", () => {
            log.trace("connecting websocket…");
            onConnected();
        });

        this.websocket.on("message", (msg) => {
            log.trace("incoming: #{msg}")
            onMsg(msg);
        });

        this.websocket.on("error", (error) => {
            log.error(error);
        });
        
        this.websocket.on("close", () => {
            log.trace("websocket closed from server");
        });
        
    }
    
    destroy() {
      this.websocket.terminate()
    }
    
}