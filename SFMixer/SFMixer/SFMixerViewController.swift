//
//  SFMixerViewController.swift
//  SFMixer
//
//  Created by CHENWANFEI on 07/03/2017.
//  Copyright © 2017 SwordFish. All rights reserved.
//

import UIKit

class SFMixerViewController: UIViewController {
    
    @IBOutlet weak var addAudioBtn: UIButton!
    @IBOutlet weak var leftPositionFlagLeftMarginConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var rightPostionFlagRightMarginConstraint: NSLayoutConstraint!
    @IBOutlet weak var actionBtn: UIBarButtonItem!

    @IBOutlet weak var leftPositionFlagView: UIView!
    
    @IBOutlet weak var rightPositionFlagView: UIView!
    
    @IBOutlet weak var leftClipIndicator: UIView!
    
    @IBOutlet weak var rightClipIndicator: UIView!
    
    @IBOutlet weak var previewBtn: UIButton!
    
    private var hairLineWidth:CGFloat{
        return CGFloat(1.0) / UIScreen.main.scale;
    }
    @IBOutlet weak var durationTitleLabel: UILabel!
    
    @IBOutlet weak var busContainerView: SFAudioBusContainerView!
    
    private var fingerX = CGFloat(0);
  
    private var halfFlagViewWidth = CGFloat(0);
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.busContainerView.parentVC = self;
        self.busContainerView.onNumOfBusesChanged = { [weak self] in
            
            guard  let `self` = self else {
                return;
            }
            
            self.addAudioBtn.isEnabled = self.busContainerView.canAddAudioBus;
            
        }
        
        halfFlagViewWidth = self.rightPositionFlagView.bounds.width / 2 - hairLineWidth;
        
        self.leftPositionFlagLeftMarginConstraint.constant = -halfFlagViewWidth;
        
        self.rightPostionFlagRightMarginConstraint.constant = halfFlagViewWidth;
        
        // Do any additional setup after loading the view.
    }
    @IBAction func onLeftPositionFlagViewPan(_ sender: Any) {
       
        if let g = sender as? UIPanGestureRecognizer{
            if g.state ==  UIGestureRecognizerState.began{
                fingerX = g.location(in: self.view).x;
                self.view.bringSubview(toFront: self.leftPositionFlagView);
                self.leftClipIndicator.isHidden = false;
            }else{
                let newFingerX = g.location(in: self.view).x;
               
                let deltaX = newFingerX - fingerX;
                
                
                var newConstant = self.leftPositionFlagLeftMarginConstraint.constant + deltaX;
                
                if newConstant <  -halfFlagViewWidth {
                    newConstant = -halfFlagViewWidth;
                }
                
                if self.busContainerView.frame.minX + newConstant > self.busContainerView.frame.maxX + self.rightPostionFlagRightMarginConstraint.constant - self.rightPositionFlagView.bounds.width{
                    newConstant = self.busContainerView.frame.maxX + self.rightPostionFlagRightMarginConstraint.constant - self.rightPositionFlagView.bounds.width - self.busContainerView.frame.minX ;
                }
                
              
                leftPositionFlagLeftMarginConstraint.constant = newConstant;
                
                self.busContainerView.clipMargins.x = newConstant + halfFlagViewWidth + hairLineWidth;
                
                fingerX = g.location(in: self.view).x;
                
                if let label = self.leftClipIndicator.subviews.last as? UILabel{
                    let passed = Float(self.busContainerView.maxSeconds) * Float(self.busContainerView.clipMargins.x) / Float(self.busContainerView.bounds.width);
                    let passSeconds = Int(passed.rounded());
                    
                    let s = String(format: "%d:%02d", passSeconds / 60, passSeconds % 60);
                    label.text = s;
                }
                
                let clippedDuration = self.busContainerView.clippedDuration;
                self.durationTitleLabel.text =  String(format: "%d:%02d", clippedDuration / 60, clippedDuration % 60);
                
                
                if g.state == .cancelled || g.state == .ended{
                    
                    UIView.animate(withDuration: ANIMATION_DURATION, animations: { [weak self] in
                        self?.leftClipIndicator.alpha = 0;
                        }, completion: {  [weak self] (_) in
                            self?.leftClipIndicator.alpha = 1;
                            self?.leftClipIndicator.isHidden = true;
                    })

                }
                
            }
        }
        
    }

    @IBAction func onRightPositionFlagViewPan(_ sender: Any) {
        
        if let g = sender as? UIPanGestureRecognizer{
            if g.state ==  UIGestureRecognizerState.began{
                fingerX = g.location(in: self.view).x;
                self.view.bringSubview(toFront: self.rightPositionFlagView);
                self.rightClipIndicator.isHidden = false;
            }else{
                let newFingerX = g.location(in: self.view).x;
                
                let deltaX = newFingerX - fingerX;
                
                
                var newConstant = self.rightPostionFlagRightMarginConstraint.constant + deltaX;
                
                if newConstant > halfFlagViewWidth {
                    newConstant = halfFlagViewWidth;
                }
                
                
                if self.busContainerView.frame.maxX + newConstant  - self.rightPositionFlagView.bounds.width < self.busContainerView.frame.minX + self.leftPositionFlagLeftMarginConstraint.constant {
                    newConstant = self.busContainerView.frame.minX + self.leftPositionFlagLeftMarginConstraint.constant + self.rightPositionFlagView.bounds.width - self.busContainerView.frame.maxX;
                }
                
                rightPostionFlagRightMarginConstraint.constant = newConstant;
                 self.busContainerView.clipMargins.y = -newConstant + halfFlagViewWidth + hairLineWidth;
                
                 fingerX = g.location(in: self.view).x;
                
                
                if let label = self.rightClipIndicator.subviews.last as? UILabel{
                    let passed = Float(self.busContainerView.maxSeconds) * Float(self.busContainerView.bounds.width -  self.busContainerView.clipMargins.y) / Float(self.busContainerView.bounds.width);
                    let passSeconds = Int(passed.rounded());
                    
                    let s = String(format: "%d:%02d", passSeconds / 60, passSeconds % 60);
                    label.text = s;
                }

                let clippedDuration = self.busContainerView.clippedDuration;
                self.durationTitleLabel.text =  String(format: "%d:%02d", clippedDuration / 60, clippedDuration % 60);
                
                if g.state == .cancelled || g.state == .ended{
                    
                    UIView.animate(withDuration: ANIMATION_DURATION, animations: { [weak self] in
                         self?.rightClipIndicator.alpha = 0;
                    }, completion: {  [weak self] (_) in
                        self?.rightClipIndicator.alpha = 1;
                        self?.rightClipIndicator.isHidden = true;
                    })
                   
                }
                
            }
        }
        
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let leftEdge = self.busContainerView.frame.minX;
        let rightEdge = self.busContainerView.frame.maxX;
        let topEdge = self.busContainerView.frame.minY - 2;
        
        self.leftClipIndicator.center = CGPoint(x: leftEdge +  self.busContainerView.clipMargins.x, y:topEdge - self.leftClipIndicator.bounds.height / 2);
        self.rightClipIndicator.center = CGPoint(x: rightEdge -  self.busContainerView.clipMargins.y, y:topEdge - self.rightClipIndicator.bounds.height / 2);
        
       
    }
    
    deinit {
        print("--------\(self) is recycled-----------");
    }
    
  
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func onAddAudio(_ sender: Any) {
        if self.busContainerView.canAddAudioBus{
            
            let no = self.busContainerView.numOfBuses;
            
            let audioBus = SFAudioBus(url: URL.init(fileURLWithPath: "http://\(no)"), name: "欢乐今宵-\(no)", startPosition: 0.0, durationForDisplay: "3:00", accerateDuration: 30.0, volumn: Float(0.3), mute: false);
            self.busContainerView.addAudioBus(audioBus: audioBus);
            self.addAudioBtn.isEnabled = self.busContainerView.canAddAudioBus;
        }
    }
    
    
    
    @IBAction func dismissMixer(_ sender: Any) {
        self.dismiss(animated: true, completion: nil);
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
