import loglevel = require('loglevel');
const WebSocket = require("ws");


export interface NetworkClient {
    destroy(): any
    send(msg: string): any
}

export class TcpClient implements NetworkClient {
    destroy() {
    }
    
    send(msg: string): any {
        
    }
}
  
export class WebsocketClient implements NetworkClient {
    websocket: any;
    
    constructor(httpPort: string, onConnected: () => any, onMsg: (msg: string) => any) {
        let log = loglevel.getLogger('ensime.socketclient');
        this.websocket = new WebSocket("ws://localhost:" + httpPort + "/jerky");
    
        this.websocket.on("open", () => {
            log.trace("connecting websocket…");
            onConnected();
        });

        this.websocket.on("message", (msg) => {
            log.trace(`incoming: ${msg}`)
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
    
    send(msg: string) {
        this.websocket.send(msg)
    }
    
}