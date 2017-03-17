//
//  SFMixerViewController.swift
//  SFMixer
//
//  Created by CHENWANFEI on 07/03/2017.
//  Copyright © 2017 SwordFish. All rights reserved.
//

import UIKit


class SFDashedLineLayer: CALayer {
    var lineColor = UIColor.red;
    
    override func draw(in ctx: CGContext) {
        //set the passed ctx in the stack's top
        UIGraphicsPushContext(ctx);
        
        
        let  path = UIBezierPath()
        
        let  p0 = CGPoint(x: self.bounds.width / 2, y: 0)
        let  p1 = CGPoint(x: self.bounds.width / 2, y: self.bounds.height);
        path.move(to: p0);
        path.addLine(to: p1);
        
        let  dashes: [ CGFloat ] = [ 3, 1 ]
        path.setLineDash(dashes, count: dashes.count, phase: 0.0)
        
        path.lineWidth = HAIRLINE_WIDTH
        
        lineColor.setStroke();
        path.stroke()
        
        
        UIGraphicsPopContext();
    
    }
    
    

}

class SFMixerViewController: UIViewController {
    
    @IBOutlet weak var addAudioBtn: UIButton!
    @IBOutlet weak var leftPositionFlagLeftMarginConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var trimBtn: UIButton!
    @IBOutlet weak var rightPostionFlagRightMarginConstraint: NSLayoutConstraint!
    @IBOutlet weak var actionBtn: UIBarButtonItem!

    @IBOutlet weak var leftPositionFlagView: UIView!
    
    @IBOutlet weak var rightPositionFlagView: UIView!
    
    @IBOutlet weak var leftClipIndicator: UIView!
    
    @IBOutlet weak var rightClipIndicator: UIView!
    
    @IBOutlet weak var midClipIndicator: UIView!
    
    @IBOutlet weak var midPositionFlagView: SFPositionFlagView!
    
    @IBOutlet weak var movingLine:SFDashedLineLayer?;
    
    @IBOutlet weak var previewBtn: UIButton!
    
    private var hairLineWidth:CGFloat{
        return CGFloat(1.0) / UIScreen.main.scale;
    }
    @IBOutlet weak var durationTitleLabel: UILabel!
    
    @IBOutlet weak var busContainerView: SFAudioBusContainerView!
    
    private var fingerX = CGFloat(0);
  
    private var halfFlagViewWidth = CGFloat(0);
    private var previewDisplayLink:CADisplayLink?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.busContainerView.parentVC = self;
        self.busContainerView.onNumOfBusesChanged = { [weak self] in
            
            guard  let `self` = self else {
                return;
            }
            
            self.addAudioBtn.isEnabled = self.busContainerView.canAddAudioBus;
            self.previewBtn.isEnabled = self.busContainerView.numOfBuses > 0;
            self.durationTitleLabel.isHidden = self.busContainerView.numOfBuses == 0;
            self.trimBtn.isEnabled = self.busContainerView.numOfBuses > 0;
            self.actionBtn.isEnabled = self.busContainerView.numOfBuses > 0;
        
        }
        
        
        
        
        
        
        
        
        halfFlagViewWidth = self.rightPositionFlagView.bounds.width / 2 - hairLineWidth;
        
        self.leftPositionFlagLeftMarginConstraint.constant = -halfFlagViewWidth;
        
        self.rightPostionFlagRightMarginConstraint.constant = halfFlagViewWidth;
        
        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func onExportResult(_ sender: Any) {
        
        let totalDuration = self.busContainerView.clipedMixRange.1;
        if totalDuration <= 0 {
            
            let ac = UIAlertController(title: "Info", message: "The length of final duration is not long enough", preferredStyle: UIAlertControllerStyle.alert);
            ac.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil));
            self.present(ac, animated: true, completion: nil);

            return;
        }
        
        let alertController = UIAlertController(title: "", message: "Please wait\n\n\n", preferredStyle: .alert)
        
        let spinnerIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        
        spinnerIndicator.center = CGPoint(x: 135.0, y: 65.5)
        spinnerIndicator.color = UIColor.black
        spinnerIndicator.startAnimating()
        
        alertController.view.addSubview(spinnerIndicator)
        self.present(alertController, animated: false, completion: nil)
        
        self.busContainerView.saveOutput(completion: { [weak self](path) in
            alertController.dismiss(animated: true, completion: nil);
            if let path = path{
                
                let url = URL(fileURLWithPath: path);
                
                let objectsToShare = [url];
                let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
                self?.present(activityVC, animated: true, completion: nil)
                
                
            }else{
                let ac = UIAlertController(title: "Error", message: "Something wrong happens", preferredStyle: UIAlertControllerStyle.alert);
                ac.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil));
                self?.present(ac, animated: true, completion: nil);

            }
        });
        
      
        
        
        
        
    }
    
    
    @IBAction func onMidPosistionFlagViewPan(_ sender: Any) {
        if let g = sender as? UIPanGestureRecognizer{
            if g.state ==  UIGestureRecognizerState.began{
                fingerX = g.location(in: self.view).x;
                self.view.bringSubview(toFront: self.midPositionFlagView);
                self.midClipIndicator.isHidden = false;
                self.busContainerView.pausePreview();
                self.previewDisplayLink?.isPaused = true;
                
            }else{
                let newFingerX = g.location(in: self.view).x;
                
                let deltaX = newFingerX - fingerX;
                
                
                var newCenterX = self.midPositionFlagView.center.x + deltaX;
                
                if newCenterX <  self.leftPositionFlagView.center.x {
                    newCenterX = self.leftPositionFlagView.center.x
                }

                if newCenterX >  self.rightPositionFlagView.center.x {
                    newCenterX = self.rightPositionFlagView.center.x
                }

                self.midPositionFlagView.center.x = newCenterX;
                CATransaction.setDisableActions(true);
                self.movingLine!.position = CGPoint(x:newCenterX,y:self.movingLine!.position.y);
                self.midClipIndicator.center.x = newCenterX;
                
                let timePassed = CGFloat(self.busContainerView.clipedMixRange.1) * (newCenterX - self.leftPositionFlagView.center.x) / self.busContainerView.distanceBetweenClipLine;
                
               
                
                if let label = self.midClipIndicator.subviews.last as? UILabel {
                    let seconds = Int(timePassed);
                    label.text = String(format: "%d:%02d", seconds / 60,seconds % 60);
                }
                
                
                
                
                if g.state == .cancelled || g.state == .ended{
                    
                    self.busContainerView.resumePreviewAtPosition(seekTime:TimeInterval(timePassed));
                    self.previewDisplayLink?.isPaused = false;
                    
                }
                
                fingerX = newFingerX;
                
            }
        }

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
                
                let clippedDuration = Int(self.busContainerView.clipedMixRange.1);
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

                let clippedDuration = Int(self.busContainerView.clipedMixRange.1);
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
            
            let url = Bundle.main.url(forResource: "audio_\(no)", withExtension: "mp3");
            
            let audioBus = SFAudioBus(url: url!, name: "auido-\(no)");
            self.busContainerView.addAudioBus(audioBus: audioBus);
            self.addAudioBtn.isEnabled = self.busContainerView.canAddAudioBus;
        }
    }
    
    
   
    
    private func onPreviewDidFinish(){
        
        self.previewDisplayLink?.invalidate();
        self.previewDisplayLink = nil;
        
        self.movingLine?.removeFromSuperlayer();
        self.movingLine = nil;
        self.midPositionFlagView.isHidden = true;
        self.midClipIndicator.isHidden = true;
        
        self.addAudioBtn.isEnabled = true;
        self.previewBtn.isSelected = false;
        self.trimBtn.isEnabled = true;
        self.leftPositionFlagView.isUserInteractionEnabled = true;
        self.rightPositionFlagView.isUserInteractionEnabled = true;
        self.actionBtn.isEnabled = true;
        
    }
    
    func runTimedCode() {
        
        if let timePassed = self.busContainerView.passedTimeSincePlaying{

            let distance = self.busContainerView.distanceBetweenClipLine;
            
            
           
            
            let delta =  distance * CGFloat(timePassed) / CGFloat(self.busContainerView.clipedMixRange.1);
            
            let beginX = self.busContainerView.frame.minX + self.busContainerView.clipMargins.x;
            
            self.midClipIndicator.center = CGPoint(x:beginX + delta,y:self.midClipIndicator.center.y);
            self.midPositionFlagView.center = CGPoint(x:beginX + delta,y:self.midPositionFlagView.center.y);
            CATransaction.setDisableActions(true);
            self.movingLine?.position = CGPoint(x : beginX + delta,y : self.movingLine!.position.y);
            
            
            
            if let label = self.midClipIndicator.subviews.last as? UILabel {
                let seconds = Int(timePassed.rounded())
                label.text = String(format: "%d:%02d", seconds / 60,seconds % 60);
            }

        }
        
        
        
        
    }
    

    @IBAction func onPreview(_ sender: Any) {
        
     
        if self.previewBtn.isSelected == false {
            let totalDuration = self.busContainerView.clipedMixRange.1;
            if totalDuration > 0 {
                
                self.addAudioBtn.isEnabled = false;
                self.previewBtn.isSelected = true;
                self.trimBtn.isEnabled = false;
                self.leftPositionFlagView.isUserInteractionEnabled = false;
                self.rightPositionFlagView.isUserInteractionEnabled = false;
                self.actionBtn.isEnabled = false;
                
                self.movingLine?.removeFromSuperlayer();
                
                let line = SFDashedLineLayer()
                line.needsDisplayOnBoundsChange = true;
                line.frame = CGRect(x:self.leftPositionFlagView.frame.midX,y:self.busContainerView.frame.minY,width:1,height:self.busContainerView.bounds.height);
                self.view.layer.addSublayer(line);
                self.movingLine = line;
                
                
                self.midClipIndicator.isHidden = false;
                self.midClipIndicator.center = CGPoint(x:self.leftPositionFlagView.frame.midX,y:self.rightClipIndicator.center.y);
                self.midPositionFlagView.isHidden = false;
                self.midPositionFlagView.center = CGPoint(x:self.leftPositionFlagView.frame.midX,y:self.rightPositionFlagView.center.y);
                
                
                
               
                
                self.busContainerView.previewMixedAudio { [weak self] in
                    
                    self?.onPreviewDidFinish();
                    
                }
                
                let dpLink = CADisplayLink(target: self, selector: #selector(runTimedCode))
                dpLink.frameInterval = 1
                
                dpLink.add(to: RunLoop.current, forMode: RunLoopMode.commonModes);
                self.previewDisplayLink = dpLink;
                
                
            }else{
                
                let ac = UIAlertController(title: "Info", message: "The length of final duration is not long enough", preferredStyle: UIAlertControllerStyle.alert);
                ac.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil));
                self.present(ac, animated: true, completion: nil);
            }
        }else{
            //stop
            self.busContainerView.stopPreview();
        }
        
        
       
      
       
        
        
        
    }
    @IBAction func onTrim(_ sender: Any) {
        
        
        let trimedClipMargin = self.busContainerView.trimedClipMargins;
        self.rightPostionFlagRightMarginConstraint.constant =  -(trimedClipMargin.y - halfFlagViewWidth);
        self.leftPositionFlagLeftMarginConstraint.constant = trimedClipMargin.x - halfFlagViewWidth;
        
        let clippedDuration = self.busContainerView.clippedDurationOfNewMargin(trimedClipMargin);
        
        self.durationTitleLabel.text =  String(format: "%d:%02d", clippedDuration / 60, clippedDuration % 60);

        
        UIView.animate(withDuration: ANIMATION_DURATION, animations: { [weak self] in
            
            self?.busContainerView.clipMargins = trimedClipMargin;
            self?.view.layoutIfNeeded();
        })

    }
   
    
    
    
    @IBAction func dismissMixer(_ sender: Any) {
        self.busContainerView.stopPreview();
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
