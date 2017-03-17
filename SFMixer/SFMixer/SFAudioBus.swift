//
//  SFAudioBus.swift
//  SFMixer
//
//  Created by CHENWANFEI on 10/03/2017.
//  Copyright © 2017 SwordFish. All rights reserved.
//

import UIKit

struct SFAudioBus:Equatable {
    var url:URL
    var name:String;
    var delayTime=TimeInterval(0)
    var accurateDuration = TimeInterval(0);
    var volumn = Float(1);
    var mute = false;
    
    var waveformImage:UIImage?
    
    init(url:URL,name:String) {
        self.url = url;
        self.name = name;
    }
 
}

func ==(lhs: SFAudioBus, rhs: SFAudioBus) -> Bool {
    return lhs.url.absoluteString == (rhs.url.absoluteString);
}
