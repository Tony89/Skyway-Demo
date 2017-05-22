//
//  StartViewController.swift
//  Skyway-Demo
//
//  Created by Tung Nguyen on 5/15/17.
//  Copyright © 2017 Tung Nguyen. All rights reserved.
//

import UIKit

class StartViewController: UIViewController {

    @IBOutlet weak var inputTextField: UITextField!
    
    @IBAction func startRoomButtonClicked(_ sender: Any) {
        guard let peerId = inputTextField.text else {
            return
        }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let navigation = storyboard.instantiateViewController(withIdentifier: "chatVideoNavigation") as? UINavigationController else {
            fatalError("couldn't find navigation with identifier")
        }
        guard let chatVideoVC = navigation.viewControllers[0] as? ViewController else {
            fatalError("couldn't find vc")
        }
        chatVideoVC.peerId = peerId
        self.navigationController?.present(navigation, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let peerId = inputTextField.text else {
            return
        }
        if segue.identifier == "chatVideoNavigation" {
            guard let navigation = segue.destination as? UINavigationController else {
                fatalError("couldn't find navigation with identifier")
            }
            guard let chatVideoVC = navigation.viewControllers[0] as? ViewController else {
                fatalError("couldn't find vc")
            }
            chatVideoVC.peerId = peerId
        }
    }
}
