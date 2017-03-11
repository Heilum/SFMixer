//
//  SFAudioBusContainerView.swift
//  SFMixer
//
//  Created by CHENWANFEI on 09/03/2017.
//  Copyright © 2017 SwordFish. All rights reserved.
//

import UIKit
import CoreGraphics


class SFAudioBusContainerClipMaskView:UIView{
    
    @IBInspectable  private var clipAreaColor:UIColor = UIColor.init(red: 249.0/255, green: 214.0/255, blue: 24.0/255, alpha: 1);
    
    var clipMargins:CGPoint = CGPoint(x:0,y:0){
        didSet{
            self.setNeedsDisplay();
        }
    }

    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        context?.addRect(CGRect(x: 0, y: 0, width: self.clipMargins.x, height: self.bounds.height))
        context?.addRect(CGRect(x: self.bounds.width - clipMargins.y, y: 0, width: self.clipMargins.y, height: self.bounds.height))
        context?.setFillColor((clipAreaColor.withAlphaComponent(0.4).cgColor));
        context?.fillPath();
        
        context?.addLines(between: [CGPoint(x:self.clipMargins.x,y: 0),CGPoint(x:self.clipMargins.x,y:self.bounds.height)]);
        context?.addLines(between: [CGPoint(x:self.bounds.width - clipMargins.y,y: 0),CGPoint(x:self.bounds.width - clipMargins.y,y:self.bounds.height)]);
        context?.setStrokeColor(clipAreaColor.cgColor);
        context?.strokePath();
    }
    
}



class SFAudioBusContainerView: UIView {
    
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
    
    @IBInspectable  var maxSeconds:Int = 120;
    @IBInspectable  private var bigTickSeconds:Int = 20;
    @IBInspectable  private var tickColor:UIColor = UIColor.white;
    @IBInspectable  private var tickFont:UIFont = UIFont.systemFont(ofSize: 10);
    @IBInspectable  private var tickMarkAreaHeight = CGFloat(25);
    @IBInspectable  private var maxAudioRow:Int = 5;
   
    
    private var clipMaskView:SFAudioBusContainerClipMaskView!
    
    
    
    
    
    override func willMove(toSuperview newSuperview: UIView?) {
        if newSuperview != nil {
            if self.clipMaskView == nil {
                let maskView = SFAudioBusContainerClipMaskView(frame: self.bounds);
                maskView.autoresizingMask = [UIViewAutoresizing.flexibleHeight,UIViewAutoresizing.flexibleWidth];
                maskView.backgroundColor = UIColor.clear;
                maskView.contentMode = UIViewContentMode.redraw;
                self.addSubview(maskView);
                self.clipMaskView = maskView;
            }
            
            
            //add gesturs
            let g = UILongPressGestureRecognizer(target: self, action: #selector(onLongPress(g:)))
            self.addGestureRecognizer(g);
        }
    }
    
    
    dynamic private func onLongPress(g:UIGestureRecognizer){
        if g.state == .began{
            var targetView:SFAudioBusView? = nil;
            for v in self.subviews{
                if let audioBusView = v as? SFAudioBusView {
                    let p = g.location(in: audioBusView);
                    if audioBusView.bounds.contains(p){
                        targetView = audioBusView;
                        break;
                    }
                }
            }
            
            if targetView != nil {
                let ac = UIAlertController(title: "Warnning" ,message: "Are you sure to reomve [\(targetView!.audioBus.name)]", preferredStyle: UIAlertControllerStyle.alert);
                
                ac.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil));
                ac.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: { [weak self] (_) in
                    self?.removeAudioBus(audioBus: targetView!.audioBus);
                }));
                self.parentVC?.present(ac, animated: true, completion: nil);
            }
        }
    }
    
    
    private var audioRowHeight:CGFloat{
        let topY = tickMarkAreaHeight;
        let rowHeiht = ( self.bounds.height - topY) / CGFloat(self.maxAudioRow);
        return rowHeiht;
    }
    
    
    
    
    override func draw(_ rect: CGRect) {
        // Drawing code
        drawRule();
        drawGrid()
       
    }
    
  
    
    
    
    private func drawGrid(){
        let totalWidth = self.bounds.width;
        var topY = self.tickFont.lineHeight + 2;
        let context = UIGraphicsGetCurrentContext()
        let gridGap = self.bigTickSeconds / 2;
        let numVerticalLine = self.maxSeconds / gridGap;
        
        let gap = totalWidth / CGFloat(numVerticalLine);
        
        
        for i in 1..<numVerticalLine  {
            let x = CGFloat(i) * gap;
            context?.addLines(between: [CGPoint(x:x,y: topY),CGPoint(x:x,y:self.bounds.height)]);
            
        }
        
        var lineColor = self.tickColor.withAlphaComponent(0.4);
        context?.setLineWidth(HAIRLINE_WIDTH);
        context?.setStrokeColor(lineColor.cgColor);
        context?.strokePath();
        
        
        //horizental lines
        topY = tickMarkAreaHeight;
        let rowHeiht = self.audioRowHeight;
        context?.addLines(between: [CGPoint(x:0,y: topY),CGPoint(x:self.bounds.width,y:topY)]);
        
        for i in 1...self.maxAudioRow{
            let y = topY + CGFloat(i) * rowHeiht;
            context?.addLines(between: [CGPoint(x:0,y: y),CGPoint(x:self.bounds.width,y:y)]);
        }
        
        lineColor = self.tickColor;
        context?.setStrokeColor(lineColor.cgColor);
        context?.strokePath();
        
        
        
    }
    
    
    private func drawRule(){
        let totalWidth = self.bounds.width;
        let numOfBigTicker = maxSeconds / bigTickSeconds;
        let bigTickWidth = totalWidth / CGFloat(numOfBigTicker);
        
        //
        
        for i in 0..<numOfBigTicker - 1 {
            let bigTickNumber = bigTickSeconds * (i+1);
            let s = "\(bigTickNumber)";
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let attrs = [NSFontAttributeName: self.tickFont, NSParagraphStyleAttributeName: paragraphStyle,NSForegroundColorAttributeName:self.tickColor] as [String : Any]
            let x = CGFloat( (i + 1)) * bigTickWidth
            let size = s.size(attributes: attrs);
            let rect = CGRect(x: x - size.width / 2, y: 0, width: size.width, height: size.height);
            s.draw(in: rect,withAttributes: attrs)
        }
        
        let hairLineWidth = CGFloat(1.0) / UIScreen.main.scale;
        let topY = self.tickFont.lineHeight + 2;
        let context = UIGraphicsGetCurrentContext()
        let minInterval = (totalWidth - CGFloat(self.maxSeconds - 1) * hairLineWidth) / CGFloat(self.maxSeconds);
        var x = minInterval;
        for i in 1..<maxSeconds  {
            var h = CGFloat(0);
            if i % bigTickSeconds == 0 {
                h = CGFloat(6);
            }else if(i % (bigTickSeconds / 2) == 0){
                h = CGFloat(4);
            }else{
                h = CGFloat(2);
            }
            //let h = (i % bigTickSeconds == 0 ? CGFloat(4) : CGFloat(2));
            context?.addLines(between: [CGPoint(x:x,y: topY),CGPoint(x:x,y:topY + h)]);
            x += minInterval + hairLineWidth;
        }
        context?.setLineWidth(hairLineWidth);
        context?.setStrokeColor(tickColor.cgColor);
        context?.strokePath();
        
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews();
        //the bus views are always arranged at front.
        UIView.animate(withDuration: ANIMATION_DURATION) { [weak self] in
            guard let `self` = self else {
                return;
            }
            for (index,v) in self.subviews.enumerated(){
                if let busView = v as? SFAudioBusView{
                    busView.frame = CGRect(x: 0, y: self.bounds.height - self.audioRowHeight * CGFloat(index + 1), width: self.bounds.width, height: self.audioRowHeight);
                }
            }
        }
        
        
       
    }
    
    var numOfBuses:Int{
        let buses =  self.subviews.reduce(0) { (sum, v) -> Int in
            if v is SFAudioBusView {
                return sum + 1;
            }else{
                return sum;
            }
        }

        return buses;
    }
    
    deinit {
        print("--------\(self) is recycled-----------");
    }
    
    // MARK:Public Area
    
    var onNumOfBusesChanged:((Void)->Void)?
    
    weak var parentVC:UIViewController?
    
    var clipMargins:CGPoint{
        get {
            return self.clipMaskView.clipMargins;
        }
        set(newValue){
            self.clipMaskView.clipMargins = newValue;
        }
    }
    
    var clippedDuration:Int{
        let duration =  ( CGFloat(self.maxSeconds) * (self.bounds.width - self.clipMargins.x - self.clipMargins.y) / self.bounds.width ).rounded();
        return Int(duration);
    }
    
    var canAddAudioBus:Bool{
    
        
        return self.numOfBuses < self.maxAudioRow;
    }
    
    
    
    
    func addAudioBus(audioBus:SFAudioBus) -> Void {
        if self.canAddAudioBus{
            let busView = SFAudioBusView(audioBus: audioBus);
            self.addSubview(busView);
            onNumOfBusesChanged?();
        }
        self.bringSubview(toFront: self.clipMaskView);
    }
    
    func removeAudioBus(audioBus:SFAudioBus){
        let targetBusView = self.subviews.filter { (v) -> Bool in
            if let busView = v as? SFAudioBusView{
                return busView.audioBus == audioBus;
            }
            return false;
            }.first ;
        
        if targetBusView != nil {
            targetBusView?.removeFromSuperview();
            
            self.bringSubview(toFront: self.clipMaskView);
            
            onNumOfBusesChanged?();
        }
        
       
    }
    
    
    
}
