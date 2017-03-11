//
//  SFAudioBusView.swift
//  SFMixer
//
//  Created by CHENWANFEI on 10/03/2017.
//  Copyright © 2017 SwordFish. All rights reserved.
//

import UIKit

class SFAudioBusView: UIView {

    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    var audioBus:SFAudioBus!
    
    init(audioBus: SFAudioBus) {
        self.audioBus = audioBus;
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0));
        
        
        let nameLabel = UILabel();
        nameLabel.font = UIFont.systemFont(ofSize: 12.0);
        nameLabel.textColor = UIColor.white;
        nameLabel.text = "\(audioBus.name) \(audioBus.durationForDisplay)";
        nameLabel.translatesAutoresizingMaskIntoConstraints = false;
        self.addSubview(nameLabel);
        
        var c = NSLayoutConstraint(item: nameLabel, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.leading, multiplier: 1, constant: 8);
        self.addConstraint(c);
        
        c = NSLayoutConstraint(item: nameLabel, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: -4);
        self.addConstraint(c);
        
        
        let volumnLabel = UILabel();
        volumnLabel.font = UIFont.systemFont(ofSize: 12.0);
        volumnLabel.textColor = UIColor.white;
        volumnLabel.text = "\(Int(audioBus.volumn * 100))";
        volumnLabel.translatesAutoresizingMaskIntoConstraints = false;
        self.addSubview(volumnLabel);
        
        c = NSLayoutConstraint(item: volumnLabel, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.trailing, multiplier: 1, constant: -8);
        self.addConstraint(c);
        
        c = NSLayoutConstraint(item: volumnLabel, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: -4);
        self.addConstraint(c);
        
        
        
        
        
    }
    

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
