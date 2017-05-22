//
//  SkywayUtil.swift
//  Asteria
//
//  Created by Nguyen Huu Anh on 11/9/16.
//  Copyright © 2016 zkai. All rights reserved.
//

import UIKit

class SkywayUtil: NSObject {
    fileprivate enum SkywayKey {
        static var APIkey: String {
            return "bd3e2070-9a15-4c4a-8960-5d08e9f2150c"
        }
        static var domain: String {
            return "stg-teacher.rarejob-z.com"
        }
    }
    
    fileprivate enum DataType: Int {
        case string = 0
        case number // 1
        case array
        case dictionary
        case data
    }
    
    var peer: SKWPeer!
    fileprivate var localMediaStream: SKWMediaStream!
    fileprivate var remoteMediaStream: SKWMediaStream!
    fileprivate var mediaConnection: SKWMediaConnection!
    fileprivate var dataConnection: SKWDataConnection!
    var remoteVideoView: SKWVideo!
    var localVideoView: SKWVideo!
    fileprivate var isMediaConnected = false
    fileprivate var isDataConnected = false
    
//    var chatViewController: FERA080ChatViewController?
    
    var didCloseChat: (() -> Void)?
    var teacherDidCall: (() -> Void)?
    var connectionDidDisconnect: (() -> Void)?
    var videoChatDidCall: (() -> Swift.Void)? = nil
    
    enum ErrorType {
        case peerEvent, dataConnection, mediaConnection
    }
    var errorOccurred: ((SKWPeerError, ErrorType) -> Void)?
    
    var commonError = NSError(domain: "SkywayUtilErrorDomain", code: 1, userInfo: nil) as Error
    
    func initializePeer(_ peerId: String) {
        let option = SKWPeerOption()
        option.key = SkywayKey.APIkey
        option.domain = SkywayKey.domain
        peer = SKWPeer(id: peerId, options: option)
    }
    
    func initializePeer(_ peerID: String, _ remotePlaceholderView: UIView, _ localPlaceholderView: UIView) {
        let option = SKWPeerOption()
        option.key = SkywayKey.APIkey
        option.domain = SkywayKey.domain
        peer = SKWPeer(id: peerID, options: option)
        setCallBacks(peer)
        
        SKWNavigator.initialize(peer)
        
        let constraints = SKWMediaConstraints()
        constraints.maxWidth = 960
        constraints.maxHeight = 540
        //	constraints.cameraPosition = SKW_CAMERA_POSITION_BACK;
        constraints.cameraPosition = SKWCameraPositionEnum.CAMERA_POSITION_FRONT
        
        localMediaStream = SKWNavigator.getUserMedia(constraints)
        
        var remoteFrame = CGRect.zero
        //remoteFrame.size.width = remotePlaceholderView.frame.height * 3.9/3
        remoteFrame.size.width = remotePlaceholderView.frame.width
        remoteFrame.size.height = remotePlaceholderView.frame.height
        remoteVideoView = SKWVideo(frame: remoteFrame)
        remotePlaceholderView.addSubview(remoteVideoView)
        remoteVideoView.isHidden = true
        remotePlaceholderView.sendSubview(toBack: remoteVideoView)
        
        var localFrame = CGRect.zero
        localFrame.size.width = localPlaceholderView.bounds.width
        localFrame.size.height = localPlaceholderView.bounds.height
        localVideoView = SKWVideo(frame: localFrame)
        localPlaceholderView.addSubview(localVideoView)
        localVideoView.addSrc(localMediaStream, track: 0)
    }
    
    func callingTo(_ strDestId: String) {
        if self.mediaConnection == nil {
            guard let mediaConnection = self.peer.call(withId: strDestId, stream: self.localMediaStream) else {
                fatalError("couldn't connect media")
            }
            self.mediaConnection = mediaConnection
            self.setMediaCallbacks(self.mediaConnection)
        }
        if dataConnection == nil {
            guard let dataConnection = peer.connect(withId: strDestId) else {
                fatalError("couldn't connect data")
            }
            self.dataConnection = dataConnection
            self.setDataCallbacks(dataConnection)
        }
    }
    
    @objc fileprivate func startMedia() {
        if self.remoteVideoView != nil {
            self.remoteVideoView.superview?.bringSubview(toFront: self.remoteVideoView)
        }
    }
    
    fileprivate func closeChat() {
        if mediaConnection != nil {
            if didCloseChat != nil {
                didCloseChat!()
            }
            if remoteMediaStream != nil {
                remoteVideoView .removeSrc(remoteMediaStream, track: 0)
                remoteMediaStream.close()
            }
            remoteMediaStream = nil
            mediaConnection.close()
        }
    }
    
    @objc func closedMedia() {
        print("media error close")
        unsetRemoteView()
        if mediaConnection != nil {
            clearMediaCallbacks(mediaConnection)
        }
        mediaConnection = nil
        if self.remoteVideoView != nil {
            self.remoteVideoView.superview?.sendSubview(toBack: self.remoteVideoView)
        }
        if self.connectionDidDisconnect != nil {
            self.connectionDidDisconnect!()
        }
    }
    
    // MARK: - Utility
    func clearViewController() {
        if mediaConnection != nil {
            clearMediaCallbacks(mediaConnection)
        }
        closeChat()
        if localMediaStream != nil {
            localMediaStream.close()
            localMediaStream = nil
        }
        if peer != nil {
            clearCallbacks(peer)
            peer.destroy()
        }
        SKWNavigator.terminate()
    }
    
    fileprivate func setRemoteView(_ stream: SKWMediaStream) {
        if isMediaConnected {
            return
        }
        isMediaConnected = true
        remoteMediaStream = stream
        DispatchQueue.main.async {
            if self.remoteVideoView != nil {
                self.remoteVideoView.isHidden = false
                self.remoteVideoView.isUserInteractionEnabled = true
                self.remoteVideoView.addSrc(self.remoteMediaStream, track: 0)
            }
        }
    }
    
    fileprivate func unsetRemoteView() {
        if !isMediaConnected {
            return
        }
        DispatchQueue.main.async {
            self.isMediaConnected = false
            if self.remoteMediaStream != nil {
                self.remoteVideoView.removeSrc(self.remoteMediaStream, track: 0)
                self.remoteMediaStream.close()
            }
            self.remoteMediaStream = nil
            self.remoteVideoView.isUserInteractionEnabled = false
            self.remoteVideoView.isHidden = true
        }
    }
    
    func exectuteStringDataSend(_ message: NSString) {
        if dataConnection != nil {
            let bResult = dataConnection.send(message)
            if bResult {
                debugPrint("send message:" + (message as String) + " successful")
            } else {
                debugPrint("send message:" + (message as String) + " fail")
            }
        }
    }
    
//    fileprivate func getMessage(_ message: JSQMessage) -> JSQMessage {
//        return message
//    }
    
    //send mesage
//    fileprivate func sendMessgae(_ sMesage: String) {
//        let sender = "Server"
//        if !sMesage.isEmpty {
//            let messageContent = sMesage
//            let message = JSQMessage(senderId: sender, displayName: sender, text: messageContent)
//            chatViewController?.getMessage(message!)
//        }
//    }
    
    // Connection
    fileprivate func setCallBacks(_ peer: SKWPeer) {
        // !!!: Event/Open
        peer.on(SKWPeerEventEnum.PEER_EVENT_OPEN) { (object) in
            DispatchQueue.main.async(execute: {
                if (object?.isKind(of: NSString.self))! {
                    guard let stringId = object as? String else { return }
                    debugPrint("your peerId: %@", stringId)
                }
            })
        }
        // !!!: Event/Call
        peer.on(SKWPeerEventEnum.PEER_EVENT_CALL) { (obj) in
            guard let mediaConnection = obj as? SKWMediaConnection else { return }
            self.mediaConnection = mediaConnection
            self.setMediaCallbacks(self.mediaConnection)
            self.mediaConnection.answer(self.localMediaStream)
//            self.chatViewController?.enableInputBar()
            if self.teacherDidCall != nil {
                self.teacherDidCall!()
            }
            if self.videoChatDidCall != nil {
                self.videoChatDidCall!()
            }
        }
        // !!!: Event/Connection
        peer.on(SKWPeerEventEnum.PEER_EVENT_CONNECTION) { (obj) in
            guard let dataConnection = obj as? SKWDataConnection else { return }
            self.dataConnection = dataConnection
            self.setDataCallbacks(self.dataConnection)
//            self.chatViewController?.enableInputBar()
            if self.remoteVideoView != nil {
                self.remoteVideoView.superview?.bringSubview(toFront: self.remoteVideoView)
            }
        }
        
        peer.on(SKWPeerEventEnum.PEER_EVENT_DISCONNECTED) { (obj) in
            self.clearViewController()
            if self.remoteVideoView != nil {
                self.remoteVideoView.superview?.sendSubview(toBack: self.remoteVideoView)
            }
            if self.connectionDidDisconnect != nil {
                self.connectionDidDisconnect!()
            }
        }
        
        peer.on(SKWPeerEventEnum.PEER_EVENT_CLOSE) { (obj) in
            self.clearViewController()
        }
        
        peer.on(SKWPeerEventEnum.PEER_EVENT_ERROR) { (obj) in
            guard let err = obj as? SKWPeerError else {
                return
            }
            DispatchQueue.main.async {
                debugPrint(err.message ?? "")
//                Crashlytics.sharedInstance().recordError(err.error ?? self.commonError, withAdditionalUserInfo: ["Type": err.type.rawValue, "Message": err.message ?? ""])
                self.errorOccurred?(err, .peerEvent)
            }
        }
    }
    
    fileprivate func clearCallbacks(_ peer: SKWPeer) {
        peer.on(SKWPeerEventEnum.PEER_EVENT_OPEN, callback: nil)
        peer.on(SKWPeerEventEnum.PEER_EVENT_CONNECTION, callback: nil)
        peer.on(SKWPeerEventEnum.PEER_EVENT_CALL, callback: nil)
        peer.on(SKWPeerEventEnum.PEER_EVENT_CLOSE, callback: nil)
        peer.on(SKWPeerEventEnum.PEER_EVENT_DISCONNECTED, callback: nil)
        peer.on(SKWPeerEventEnum.PEER_EVENT_ERROR, callback: nil)
    }
    
    fileprivate func clearMediaCallbacks(_ media: SKWMediaConnection) {
        media.on(SKWMediaConnectionEventEnum.MEDIACONNECTION_EVENT_STREAM, callback: nil)
        media.on(SKWMediaConnectionEventEnum.MEDIACONNECTION_EVENT_CLOSE, callback: nil)
        media.on(SKWMediaConnectionEventEnum.MEDIACONNECTION_EVENT_ERROR, callback: nil)
    }
    
    fileprivate func clearDataCallbacks(_ data: SKWDataConnection) {
        data.on(SKWDataConnectionEventEnum.DATACONNECTION_EVENT_OPEN, callback: nil)
        data.on(SKWDataConnectionEventEnum.DATACONNECTION_EVENT_DATA, callback: nil)
        data.on(SKWDataConnectionEventEnum.DATACONNECTION_EVENT_CLOSE, callback: nil)
        data.on(SKWDataConnectionEventEnum.DATACONNECTION_EVENT_ERROR, callback: nil)
    }
    
    fileprivate func cycleLocalCamera() {
        var pos = localMediaStream.getCameraPosition()
        if pos == SKWCameraPositionEnum.CAMERA_POSITION_FRONT {
            pos = SKWCameraPositionEnum.CAMERA_POSITION_BACK
        } else {
            pos = SKWCameraPositionEnum.CAMERA_POSITION_FRONT
        }
        localMediaStream.setCameraPosition(pos)
    }
    fileprivate func setDataCallbacks(_ data: SKWDataConnection) {
        // !!!: DataEvent/Open
        data.on(SKWDataConnectionEventEnum.DATACONNECTION_EVENT_OPEN) { (obj) in
            self.isDataConnected = true
            // Handle data connection open
        }
        // !!!: DataEvent/Data
        data.on(SKWDataConnectionEventEnum.DATACONNECTION_EVENT_DATA) { (obj) in
            if (obj?.isKind(of: NSString.self))! {
                DispatchQueue.main.async {
                    guard let stringData = obj as? String else { return }
//                    self.sendMessgae(stringData)
                }
            }
        }
        
        // !!!: DataEvent/Close
        data.on(SKWDataConnectionEventEnum.DATACONNECTION_EVENT_CLOSE) { (obj) in
            self.isDataConnected = false
            self.performSelector(onMainThread: #selector(self.closeData),
                                 with: nil,
                                 waitUntilDone: false)
        }
        
        data.on(SKWDataConnectionEventEnum.DATACONNECTION_EVENT_ERROR) { (obj) in
            guard let err = obj as? SKWPeerError else {
                return
            }
            debugPrint(err.message ?? "")
            DispatchQueue.main.async {
                debugPrint(err.message ?? "")
//                Crashlytics.sharedInstance().recordError(err.error ?? self.commonError, withAdditionalUserInfo: ["Type": err.type.rawValue, "Message": err.message ?? ""])
                self.errorOccurred?(err, .dataConnection)
            }
        }
    }
    
    @objc fileprivate func closeData() {
        if dataConnection != nil {
            self.clearDataCallbacks(dataConnection)
            dataConnection = nil
        }
//        chatViewController?.disableInputBar()
    }
    
    fileprivate func setMediaCallbacks(_ media: SKWMediaConnection) {
        // !!!: MediaEvent/Stream
        media.on(SKWMediaConnectionEventEnum.MEDIACONNECTION_EVENT_STREAM) { (obj) in
            // Add Stream;
            guard let stream = obj as? SKWMediaStream else { return }
            self.setRemoteView(stream)
            self.performSelector(onMainThread: #selector(self.startMedia),
                                 with: nil,
                                 waitUntilDone: false)
        }
        // !!!: MediaEvent/Close
        media.on(SKWMediaConnectionEventEnum.MEDIACONNECTION_EVENT_CLOSE) { (obj) in
            
            self.performSelector(onMainThread: #selector(self.closedMedia),
                                 with: nil,
                                 waitUntilDone: false)
        }
        // !!!: MediaEvent/Error
        media.on(SKWMediaConnectionEventEnum.MEDIACONNECTION_EVENT_ERROR) { (obj) in
            guard let err = obj as? SKWPeerError else {
                return
            }
            DispatchQueue.main.async {
                debugPrint(err.message ?? "")
//                Crashlytics.sharedInstance().recordError(err.error ?? self.commonError, withAdditionalUserInfo: ["Type": err.type.rawValue, "Message": err.message ?? ""])
                if !self.isMediaConnected && !self.isDataConnected {
                    self.errorOccurred?(err, .mediaConnection)
                }
            }
        }
    }
    
    func muteLocal(_ isMute: Bool) {
        guard localMediaStream != nil else {
            return
        }
        if isMute {
            localMediaStream.setEnableAudioTrack(0, enable:true)
        } else {
            localMediaStream.setEnableAudioTrack(0, enable:false)
        }
    }
    
    func disableVideoLocal(_ isDisable: Bool) {
        guard localMediaStream != nil else {
            return
        }
        if localMediaStream != nil {
            localMediaStream.setEnableVideoTrack(0, enable: isDisable)
        }
    }
}
