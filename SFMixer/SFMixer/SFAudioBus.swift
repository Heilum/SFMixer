//
//  SFAudioBus.swift
//  SFMixer
//
//  Created by CHENWANFEI on 10/03/2017.
//  Copyright © 2017 SwordFish. All rights reserved.
//

import Foundation

struct SFAudioBus:Equatable {
    var url:URL
    var name:String;
    var startPosition:TimeInterval;
    var durationForDisplay:String;
    var accerateDuration:TimeInterval;
    var volumn:Float;
    var mute:Bool;
    
 
}

func ==(lhs: SFAudioBus, rhs: SFAudioBus) -> Bool {
    return lhs.url.absoluteString == (rhs.url.absoluteString);
}
