//
//  SFPositionFlagView.swift
//  SFMixer
//
//  Created by CHENWANFEI on 07/03/2017.
//  Copyright © 2017 SwordFish. All rights reserved.
//

import UIKit

class SFPositionFlagView: UIView {
    
    

    override func draw(_ rect: CGRect) {
        let leftMargin = CGFloat(5.0);
        let rightMargin = CGFloat(5.0);
        let bottomMargin = CGFloat(5.0);
        
        let trangleHeight = CGFloat(10.0);
        let trangleBottom = rect.width - leftMargin - rightMargin;
        
       
        
        let p0 = CGPoint(x:rect.size.width / 2,y:rect.height - bottomMargin - trangleHeight);
        let p1 = CGPoint(x:p0.x - trangleBottom / 2, y: rect.height - bottomMargin );
        let p2 = CGPoint(x:p0.x + trangleBottom / 2, y: rect.height - bottomMargin );
        
        //let path = CGMutablePath();
        let context = UIGraphicsGetCurrentContext();
        context?.setLineWidth(HAIRLINE_WIDTH);
        context?.setFillColor(self.tintColor.cgColor);
        context?.setStrokeColor(self.tintColor.cgColor);
        context?.move(to: CGPoint(x: rect.size.width / 2, y: 0));
        context?.addLine(to: p0);
        context?.strokePath();
        //context?.closePath();
 
        context?.move(to: p0);
        context?.addLine(to: p1);
        context?.addLine(to: p2);
        context?.fillPath();
        
        
        
        
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
