//
//  ViewController.swift
//  Skyway-Demo
//
//  Created by Tung Nguyen on 5/11/17.
//  Copyright © 2017 Tung Nguyen. All rights reserved.
//

import UIKit

protocol ViewControllerDelegate {
    func didSelectPeer(_ connectPeerId: String!)
}

class ViewController: UIViewController {
    @IBOutlet weak var remotePlaceholderView: UIView!
    @IBOutlet weak var localPlaceholderView: UIView!
    @IBOutlet weak var connectToBarButton: UIButton!
    fileprivate var skywayUtil = SkywayUtil()
    var peerId: String!
    
    var connectPeerId: String = "" {
        didSet {
            if connectPeerId != "" {
                connectToBarButton.isEnabled = false
            }
        }
    }
    
    @IBAction func connectToBarButtonClicked(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let navigation = storyboard.instantiateViewController(withIdentifier: "peerListNavigation") as? UINavigationController else {
            fatalError("couldn't find navigation with identifier")
        }
        guard let peerListVC = navigation.viewControllers[0] as? CounselorTableViewController else {
            fatalError("couldn't find peer list vc")
        }
        peerListVC.skywayUtil = self.skywayUtil
        peerListVC.currentPeerId = peerId
        peerListVC.delegate = self
        self.navigationController?.present(navigation, animated: true, completion: nil)
    }
    
    @IBAction func closeBarButtonClicked(_ sender: Any) {
        self.navigationController?.dismiss(animated: true, completion: {
            self.skywayUtil.clearViewController()
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        initSkywayUtil()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if skywayUtil.remoteVideoView != nil {
            var remoteFrame = CGRect.zero
            //remoteFrame.size.width = remotePlaceholderView.frame.height * 3.9/3
            remoteFrame.size.width = remotePlaceholderView.frame.width
            remoteFrame.size.height = remotePlaceholderView.frame.height
            skywayUtil.remoteVideoView.frame = remoteFrame
        }
        UIApplication.shared.isIdleTimerDisabled = true
//        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0, execute: {
//            self.skywayUtil.callingTo("tony")
//        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        UIApplication.shared.isIdleTimerDisabled = false
        super.viewDidDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

//    func randomString(length: Int) -> String {
//        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
//        let len = UInt32(letters.length)
//        
//        var randomString = ""
//        
//        for _ in 0 ..< length {
//            let rand = arc4random_uniform(len)
//            var nextChar = letters.character(at: Int(rand))
//            randomString += NSString(characters: &nextChar, length: 1) as String
//        }
//        
//        return randomString
//    }
    
    fileprivate func initSkywayUtil() {
        guard let peerID: String = self.peerId else {
            fatalError("SkyWay peer ID is empty.")
        }
        skywayUtil.initializePeer(peerID, remotePlaceholderView, localPlaceholderView)
        self.view.bringSubview(toFront: localPlaceholderView)
//        skywayUtil.chatViewController = chatViewController
//        remotePlaceholderView.bringSubview(toFront: overlayRemoteView)
//        skywayUtil.teacherDidCall = {
//            self.teacherDidCall()
//        }
//        skywayUtil.connectionDidDisconnect = {
//            self.endLesson()
//        }
        skywayUtil.videoChatDidCall = {
            self.connectToBarButton.isEnabled = false
        }
        
        skywayUtil.connectionDidDisconnect = {
            self.connectToBarButton.isEnabled = true
        }
        
        skywayUtil.errorOccurred = { error, type in
            self.skywayUtil.clearViewController()
            var message = "OKボタンを押すと復帰を試みます。それでも復帰しない場合はアプリを再起動してください。"
            #if DEV || PH2_DEV
                if error.message != nil {
                    message += "\n\n" + error.message
                }
            #endif
//            self.showReconnectDialog(title: "通信エラーが発生しました。", message: message)
        }
    }
}

extension ViewController: ViewControllerDelegate {
    func didSelectPeer(_ connectPeerId: String!) {
        self.connectPeerId = connectPeerId
        self.skywayUtil.callingTo(connectPeerId)
    }
}

