//
//  SFAudioBusView.swift
//  SFMixer
//
//  Created by CHENWANFEI on 10/03/2017.
//  Copyright © 2017 SwordFish. All rights reserved.
//

import UIKit

import MediaPlayer
import AVFoundation

class SFAudioBusView: UIView {
    
    
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
    
    var audioBus:SFAudioBus!
    
    private weak var nameLabel:UILabel!
    private weak var volumnLabel:UILabel!
    
    private weak var waveFormView:UIImageView!
    
    private weak var indictor:UIActivityIndicatorView!
    
    private let bottomLineHeight = CGFloat(20)
    private let waveformImageVerticalMargin = CGFloat(8)
    private let maxDuration:CGFloat;
    
    private var lastPanLocation:CGPoint?
    
    
    private weak var leftSliderFlagView:UIView!
    private weak var rightSliderFlagView:UIView!
    

    
    
    init(audioBus: SFAudioBus,frame:CGRect,maxDuration:CGFloat) {
        self.audioBus = audioBus;
        self.maxDuration = maxDuration;
        super.init(frame: frame);
        
        
        
        
        
        let nameLabel = UILabel();
        nameLabel.font = UIFont.systemFont(ofSize: 12.0);
        nameLabel.textColor = UIColor.white;
        nameLabel.translatesAutoresizingMaskIntoConstraints = false;
        self.addSubview(nameLabel);
        self.nameLabel = nameLabel;
        
        var c = NSLayoutConstraint(item: nameLabel, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.leading, multiplier: 1, constant: 8);
        self.addConstraint(c);
        
        c = NSLayoutConstraint(item: nameLabel, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: -4);
        self.addConstraint(c);
        
        
        let volumnLabel = UILabel();
        volumnLabel.font = UIFont.systemFont(ofSize: 12.0);
        volumnLabel.textColor = UIColor.white;
        volumnLabel.translatesAutoresizingMaskIntoConstraints = false;
        self.addSubview(volumnLabel);
        self.volumnLabel = volumnLabel;
        
        c = NSLayoutConstraint(item: volumnLabel, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.trailing, multiplier: 1, constant: -8);
        self.addConstraint(c);
        
        c = NSLayoutConstraint(item: volumnLabel, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: -4);
        self.addConstraint(c);
        
        
        
        //data
        
        let asset = AVURLAsset(url: self.audioBus.url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: NSNumber(value: true as Bool)])
        let audioDuration = asset.duration;
        self.audioBus.accurateDuration = CMTimeGetSeconds(audioDuration);

        
        
        
        
        //add waveformView
        
        let waveformFrame = CGRect(x: 0, y: waveformImageVerticalMargin, width: self.bounds.width * CGFloat( self.audioBus.accurateDuration) / self.maxDuration, height:waveformHeight);
        let waveFormView = UIImageView(frame: waveformFrame);
        waveFormView.tintColor = UIColor.white;
        //waveFormView.backgroundColor = UIColor.red;
        self.addSubview(waveFormView);
        self.waveFormView = waveFormView;
        waveFormView.center = CGPoint(x: self.bounds.width / 2, y: self.waveFormView.center.y);
        
        
        self.audioBus.delayTime = TimeInterval( self.maxDuration * self.waveFormView.frame.minX / self.bounds.width );
        
        
        
        
        
        //add indicator
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.white);
        indicator.translatesAutoresizingMaskIntoConstraints = false;
        self.waveFormView.addSubview(indicator);
        indicator.startAnimating();
        self.indictor = indicator;
        
        c = NSLayoutConstraint(item: indicator, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: self.waveFormView, attribute: NSLayoutAttribute.centerX, multiplier: 1, constant: 0);
        self.waveFormView.addConstraint(c);
        
        c = NSLayoutConstraint(item: indicator, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: self.waveFormView, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0);
        self.waveFormView.addConstraint(c);


        
        
        
        
        
        
        
        
        //add gesturs
        let longPressG = UILongPressGestureRecognizer(target: self, action: #selector(onLongPress(g:)))
        self.addGestureRecognizer(longPressG);
        
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap(g:)))
        self.addGestureRecognizer(tap);
        
        
        
        //
        let iDuration = Int(self.audioBus.accurateDuration);
        self.nameLabel.text = "\(self.audioBus.name)  \(iDuration / 60):\(iDuration % 60)"
        self.volumnLabel.text = "Vol:\(Int(self.audioBus.volumn * 100))";

        
        let scale = UIScreen.main.scale;
        
        generateWaveformImage(audioURL: self.audioBus.url, imageSizeInPixel: CGSize(width:self.bounds.width * scale,height:self.waveformHeight * scale), waveColor: UIColor.white) { [weak self](waveformImage) in
            
            guard let `self` = self else{
                return;
            }
            
            if let image = waveformImage{
                self.audioBus.waveformImage = waveformImage;
                self.waveFormView.image = image.withRenderingMode(UIImageRenderingMode.alwaysTemplate);
                self.indictor.removeFromSuperview();
                
                //add  pan gestures
                var pan = PanDirectionGestureRecognizer(direction:.horizontal, target: self, action: #selector(self.onPanWaveformHorizental(gesture:)));
                self.addGestureRecognizer(pan);
                
                pan = PanDirectionGestureRecognizer(direction:.vertical, target: self, action: #selector(self.onPanWaveformVertical(gesture:)));
                
                self.addGestureRecognizer(pan);
                
            }else{
                self.nameLabel.text = "\(self.audioBus.name) loading fails";
                self.nameLabel.textColor = UIColor.red;
            }
        }

        
    }
    
    
    dynamic private func onPanWaveformVertical(gesture:UIGestureRecognizer){
        guard  self.audioBus.waveformImage != nil else {
            return;
        }
        
        if gesture.state == .began{
            self.lastPanLocation = gesture.location(in: self);
        }else if(gesture.state == .changed) {
            let thisPanLocation = gesture.location(in: self);
            let deltaY = thisPanLocation.y - lastPanLocation!.y;
            let delta = UIScreen.main.scale / 2;
            if deltaY > 0 {
                //down
                self.waveFormView.bounds = CGRect(x:0,y:0,width:self.waveFormView.bounds.width,height:max(self.waveFormView.bounds.height - delta,0));
                
            }else{
                //up
                 self.waveFormView.bounds = CGRect(x:0,y:0,width:self.waveFormView.bounds.width,height:min(self.waveFormView.bounds.height + delta,waveformHeight));
            }
            
            self.audioBus.volumn = Float(self.waveFormView.bounds.height / waveformHeight);
            
            let iVolumn = Int((100.0 * self.audioBus.volumn).rounded())
            self.volumnLabel.text = "Vol:\(iVolumn)"

           
            
            self.lastPanLocation = thisPanLocation;
        }
    }
    
    
 
    
    dynamic private func onPanWaveformHorizental(gesture:UIGestureRecognizer){
        
        guard  self.audioBus.waveformImage != nil else {
            return;
        }
        
        if gesture.state == .began{
            self.lastPanLocation = gesture.location(in: self);
            
        }else if(gesture.state == .changed){
            
            
            
            let thisPanLocation = gesture.location(in: self);
            let deltaX = thisPanLocation.x - self.lastPanLocation!.x;
            self.waveFormView.center = CGPoint(x: self.waveFormView.center.x + deltaX, y: self.waveFormView.center.y);
            
            if self.waveFormView.frame.maxX < 0{
                self.waveFormView.frame = CGRect(x: -self.waveFormView.bounds.width, y: self.waveFormView.frame.origin.y, width: self.waveFormView.frame.width, height: self.waveFormView.frame.height);
            }
            
            if self.waveFormView.frame.minX > self.bounds.width{
                self.waveFormView.frame = CGRect(x: self.bounds.width, y: self.waveFormView.frame.origin.y, width: self.waveFormView.frame.width, height: self.waveFormView.frame.height);
            }
            
            if self.leftSliderFlagView == nil && self.rightSliderFlagView == nil {
                
                
                //add flagView
                
                let leftFlagView = createFlagView();
                self.superview!.addSubview(leftFlagView);
                self.leftSliderFlagView = leftFlagView;
                
                let rightFlagView = createFlagView();
                self.superview!.addSubview(rightFlagView);
                self.rightSliderFlagView = rightFlagView;
                
            
            }
            
         
            
            let leftValue =  Int(self.maxDuration * self.waveFormView.frame.minX / self.bounds.width);
            let rightValue =  Int(self.maxDuration *  self.waveFormView.frame.maxX / self.bounds.width);
            
            let leftLabel = self.leftSliderFlagView.subviews.last as! UILabel;
            leftLabel.text = String(format:"\(leftValue / 60):%02d",leftValue % 60);
            
            let rightLabel = self.rightSliderFlagView.subviews.last as! UILabel;
            rightLabel.text = String(format:"\(rightValue / 60):%02d",rightValue % 60);
            
            
            let referenceFrame = self.convert(self.waveFormView.frame, to: self.superview!);
            
            self.leftSliderFlagView.center = CGPoint(x : referenceFrame.minX,y:referenceFrame.minY - self.leftSliderFlagView.bounds.height / 2);
            
            self.rightSliderFlagView.center = CGPoint(x : referenceFrame.maxX,y:referenceFrame.minY - self.rightSliderFlagView.bounds.height / 2);
            
            
            
            
            self.audioBus.delayTime = TimeInterval( self.maxDuration * self.waveFormView.frame.minX / self.bounds.width );
            
            self.lastPanLocation = thisPanLocation;
            
        }else if gesture.state == .cancelled || gesture.state == .ended{
            
            UIView.animate(withDuration: ANIMATION_DURATION, animations: { [weak self] in
                
                self?.leftSliderFlagView?.alpha = 0;
                self?.rightSliderFlagView?.alpha = 0;
                
                }, completion: { [weak self]  (_) in
                    
                    self?.leftSliderFlagView?.removeFromSuperview();
                    self?.rightSliderFlagView?.removeFromSuperview();
            })
            
        }

    }
    
   

    
   
    private var waveformHeight:CGFloat{
        return self.bounds.height  - self.bottomLineHeight - waveformImageVerticalMargin * 2
    }
    
    
    
    
    
    
    
    private func createFlagView() -> UIView{
        let flagView = UIView(frame: CGRect(x: 0, y: 0, width: 33.0, height: 24.0))
        let imageView = UIImageView(frame: flagView.bounds);
        imageView.image = UIImage(named: "popover");
        flagView.addSubview(imageView);
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 33.0, height: 21.0));
        label.font = UIFont.systemFont(ofSize: 10.0);
        label.textAlignment = NSTextAlignment.center;
        label.textColor = UIColor.white;
        flagView.addSubview(label);
        
        return flagView;

    }
    
    
    dynamic private func onTap(g:UIGestureRecognizer){
        if g.state == .ended{
            
            if self.audioBus.waveformImage != nil{
                self.audioBus.mute = !self.audioBus.mute;
                if self.audioBus.mute{
                    self.nameLabel.textColor = UIColor.darkGray;
                    self.volumnLabel.textColor = UIColor.darkGray;
                    self.waveFormView.tintColor = UIColor.darkGray;
                    if let panG =  self.gestureRecognizers?.filter({ (g) -> Bool in
                        g is UIPanGestureRecognizer
                    }).first{
                        panG.isEnabled = false;
                    }
                    
                }else{
                    self.nameLabel.textColor = UIColor.white;
                    self.volumnLabel.textColor = UIColor.white;
                    self.waveFormView.tintColor = UIColor.white;
                    
                    if let panG =  self.gestureRecognizers?.filter({ (g) -> Bool in
                        g is UIPanGestureRecognizer
                    }).first{
                        panG.isEnabled = true;
                    }
                }
            }
         
        }
    }
    
    
    dynamic private func onLongPress(g:UIGestureRecognizer){
        if g.state == .began{
            if let containerView = self.superview as? SFAudioBusContainerView {
                containerView.prepareRemoveAudioBusView(targetView: self);
            }
        }
    }
    
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    var rightMargin:CGFloat{
        return self.bounds.width -  self.waveFormView.frame.maxX;
    }
    var leftMargin:CGFloat{
        return self.waveFormView.frame.minX;
    }
    
}
