//
//  ViewController.swift
//  SFMixer
//
//  Created by CHENWANFEI on 07/03/2017.
//  Copyright © 2017 SwordFish. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func showMixer(_ sender: Any) {
        
      
        
        let nc = UIStoryboard(name: "SFMixerViewController", bundle: nil).instantiateInitialViewController();
        
        self.present(nc!, animated: true, completion: nil);
    }

}

