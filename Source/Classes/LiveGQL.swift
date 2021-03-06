//
//  LiveGQL.swift
//  graphql-subscription
//
//  Created by Florian Mari on 06/07/2017.
//  Copyright © 2017 Florian. All rights reserved.
//

import Foundation
import Starscream
import JSONCodable

open class LiveGQL {
    private(set) var socket: WebSocket
    public weak var delegate: LiveGQLDelegate?
    
    public init(socket url: String) {
        self.socket = WebSocket(url: URL(string: url)!, protocols: ["graphql-ws"])
        self.socket.delegate = self
        self.socket.connect()
    }
    
    private func sendMessage(_ message: OperationMessage) {
        do {
            let serializedMessage = try message.toJSONString()
            if socket.isConnected {
                socket.write(string: serializedMessage)
            }
        } catch {
            print(error)
        }
    }
    
    fileprivate func errorHandler(_ message: String) {
        
    }
    
    public func initServer() {
        let unserializedMessage = OperationMessage(
            payload: nil,
            id: nil,
            type: MessageTypes.GQL_CONNECTION_INIT.rawValue)
        self.sendMessage(unserializedMessage)
    }
    
    public func subscribe(graphql query: String, identifier: String) {
        let unserializedMessage = OperationMessage(
            payload: Payload(query: query,
                             variables: nil,
                             operationName: nil),
            id: identifier,
            type: MessageTypes.GQL_START.rawValue
        )
        self.sendMessage(unserializedMessage)
    }
    
    public func unsubscribe(subscribtion identifier: String) {
        let unserializedMessage = OperationMessage(
            payload: nil,
            id: identifier,
            type: MessageTypes.GQL_STOP.rawValue
        )
        self.sendMessage(unserializedMessage)
    }
    
    public func closeConnection() {
        let unserializedMessage = OperationMessage(
            payload: nil,
            id: nil,
            type: MessageTypes.GQL_CONNECTION_TERMINATE.rawValue
        )
        self.sendMessage(unserializedMessage)
    }
    
    public func isConnected() -> Bool {
        return socket.isConnected
    }
    
    deinit {
        self.socket.disconnect(forceTimeout: 0)
        self.socket.delegate = nil
    }
}

extension LiveGQL : WebSocketDelegate {
    public func websocketDidConnect(socket: Starscream.WebSocket) {
        print("LiveGQL: Connected to socket")
    }
    
    public func websocketDidDisconnect(socket: Starscream.WebSocket, error: NSError?) {
    }
    
    public func websocketDidReceiveMessage(socket: Starscream.WebSocket, text: String) {
        self.errorHandler(text)
        self.delegate?.receivedMessage(text: text)
    }
    
    public func websocketDidReceiveData(socket: Starscream.WebSocket, data: Data) {
        print("Data received")
        print(data)
    }
}

public protocol LiveGQLDelegate: class {
    func receivedMessage(text: String)
}
