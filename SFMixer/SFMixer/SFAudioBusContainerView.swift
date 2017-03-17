//
//  SFAudioBusContainerView.swift
//  SFMixer
//
//  Created by CHENWANFEI on 09/03/2017.
//  Copyright © 2017 SwordFish. All rights reserved.
//

import UIKit
import CoreGraphics
import AVFoundation



private class SFAudioBusContainerClipMaskLayer:CALayer{
    
    
    var clipAreaColor:UIColor!;
    
    @NSManaged var clipMargins:CGPoint;
    
    class override func needsDisplay(forKey key:String) -> Bool {
        if key == "clipMargins" {
            return true
        } else {
            return super.needsDisplay(forKey: key)
        }
    }
    
    
    
    override func draw(in ctx: CGContext) {
        let context = ctx
        context.addRect(CGRect(x: 0, y: 0, width: clipMargins.x, height: self.bounds.height))
        context.addRect(CGRect(x: self.bounds.width - clipMargins.y, y: 0, width: clipMargins.y, height: self.bounds.height))
        context.setFillColor((clipAreaColor.withAlphaComponent(0.4).cgColor));
        context.fillPath();
        
        context.addLines(between: [CGPoint(x:clipMargins.x,y: 0),CGPoint(x:clipMargins.x,y:self.bounds.height)]);
        context.addLines(between: [CGPoint(x:self.bounds.width - clipMargins.y,y: 0),CGPoint(x:self.bounds.width - clipMargins.y,y:self.bounds.height)]);
        context.setStrokeColor(clipAreaColor.cgColor);
        context.strokePath();
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
    @IBInspectable  fileprivate var clipAreaColor:UIColor = UIColor.init(red: 0, green: 122.0/255, blue: 1, alpha: 1);
    
    
    
    private weak var clipMaskLayer:SFAudioBusContainerClipMaskLayer!
    
    private var avPlayer:AVPlayer?
    
    
    private var playingBeginTime:TimeInterval?
    
    
    
    override func willMove(toSuperview newSuperview: UIView?) {
        if newSuperview != nil {
            
            
            
            
            
            //add mask layer
            let maskLayer = SFAudioBusContainerClipMaskLayer();
            
            maskLayer.needsDisplayOnBoundsChange = true;
            maskLayer.zPosition = CGFloat(MAXFLOAT);
            maskLayer.clipAreaColor = self.clipAreaColor;
            maskLayer.clipMargins = CGPoint(x: 0, y: 0);
            
            self.layer.addSublayer(maskLayer);
            self.clipMaskLayer = maskLayer;
        }else{
            stopPreview()
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
        
        self.clipMaskLayer?.frame = self.bounds;
        
        
        
        
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
    
    private var previewDidFinish:((Void)->Void)?
    
    weak var parentVC:SFMixerViewController?
    
    var clipMargins:CGPoint{
        set{
            // self.clipMaskLayer is an instance of SFAudioBusContainerClipMaskLayer
            // change the property animately
            self.clipMaskLayer.clipMargins = newValue;
        }
        get{
            let p = self.clipMaskLayer.clipMargins;
            print(p);
            return p;
        }
    }
    
    
  
    
    var canAddAudioBus:Bool{
        return self.numOfBuses < self.maxAudioRow;
    }
    
    func clippedDurationOfNewMargin(_ newMargin:CGPoint) -> Int{
        let duration =  ( CGFloat(self.maxSeconds) * (self.bounds.width - newMargin.x - newMargin.y) / self.bounds.width ).rounded();
        return Int(duration);
    }
    
    
    func addAudioBus(audioBus:SFAudioBus) -> Void {
        if self.canAddAudioBus{
            let busView = SFAudioBusView(audioBus: audioBus, frame: CGRect(x:0,y:0,width:self.bounds.width,height:audioRowHeight),maxDuration:CGFloat(self.maxSeconds))
            self.addSubview(busView);
            onNumOfBusesChanged?();
        }
        
    }
    
    
    func prepareRemoveAudioBusView(targetView:SFAudioBusView){
        let ac = UIAlertController(title: "Warnning" ,message: "Are you sure to reomve [\(targetView.audioBus.name)]", preferredStyle: UIAlertControllerStyle.alert);
        
        ac.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil));
        ac.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: { [weak self] (_) in
            targetView.removeFromSuperview();
            self?.onNumOfBusesChanged?();
        }));
        self.parentVC?.present(ac, animated: true, completion: nil);
    }
    
    
    private func addAudioBus(_ audioBus:SFAudioBus,composition:AVMutableComposition) -> AVAudioMixInputParameters?{
        let asset =  AVURLAsset(url: audioBus.url);
        let track = composition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid);
        
        
        
        let startTime = CMTime(seconds: 0, preferredTimescale: 1);
        let endTime = CMTime(seconds: audioBus.accurateDuration, preferredTimescale: 1);
        
        let trackMixParameters = AVMutableAudioMixInputParameters(track: track);
        trackMixParameters.setVolume(audioBus.volumn, at: startTime);
        
        
        let sourceTrack = asset.tracks(withMediaType: AVMediaTypeAudio).first!
        
        var timeRange = CMTimeRange(start: startTime, duration: endTime);
        var delayTime = CMTime(seconds: audioBus.delayTime, preferredTimescale: 1);
        
        if audioBus.delayTime < 0{
            timeRange.start = CMTime(seconds: -audioBus.delayTime, preferredTimescale: 1);
            delayTime = startTime;
        }
        
        
        
        do {
            try track.insertTimeRange(timeRange, of: sourceTrack, at:delayTime);
        }catch{
            print(error);
            return nil;
        }
        
        
        
        return trackMixParameters;
        
    }
    
    private func createAudioMixerAndComposition() -> (AVAudioMix,AVComposition)?{
        let composition = AVMutableComposition();
        var inputParams = [AVAudioMixInputParameters]();
        for v in self.subviews{
            if let busView = v as? SFAudioBusView{
                
                if busView.audioBus.mute == false{
                    
                    if let param = self.addAudioBus(busView.audioBus, composition: composition){
                        inputParams.append(param);
                    }else{
                        return nil;
                    }
                    
                }
                
                
            }
        }
        
        
        let audioMixer = AVMutableAudioMix();
        audioMixer.inputParameters = inputParams;
        
        
        return (audioMixer,composition);
        
    }
    
    func saveOutput(completion:@escaping (String?) -> Void){
        
        if let (audioMixer,composition)  = self.createAudioMixerAndComposition() {
            
            let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A)!
            exporter.audioMix = audioMixer;
            exporter.outputFileType = "com.apple.m4a-audio";
            
            let fileName = "SFMixer.m4a";
            let finalPath = (NSTemporaryDirectory() as NSString).appendingPathComponent(fileName)
            
            
            
            print(finalPath);
            
            let outputURL = URL(fileURLWithPath: finalPath);
            
            try? FileManager.default.removeItem(at: outputURL);
            exporter.outputURL = outputURL;
            
            let range = self.clipedMixRange;
            exporter.timeRange = CMTimeRange(start: CMTime(seconds: range.0, preferredTimescale: 1), duration: CMTime(seconds: range.1, preferredTimescale: 1))
            
            exporter.exportAsynchronously {
                
                let status = exporter.status;
                if status == .completed{
                    DispatchQueue.main.async {
                        completion(finalPath);
                    }
                }else if(status == .failed){
                    DispatchQueue.main.async {
                        completion(nil);
                    }
                }
            };
        }else{
            completion(nil);
        }
        
    }
    
    
    
    
    var clipedMixRange:(TimeInterval,TimeInterval){
        let leftClip = TimeInterval(self.maxSeconds) * TimeInterval( self.clipMargins.x / self.bounds.width);
        let rightClip = TimeInterval(self.maxSeconds) * TimeInterval( self.clipMargins.y / self.bounds.width);
        let duration = TimeInterval(self.maxSeconds) - leftClip - rightClip;
        return(leftClip,duration);
        //return Range<TimeInterval>(
    }
    
    var distanceBetweenClipLine:CGFloat{
        let distance = self.bounds.width - self.clipMargins.x - self.clipMargins.y;
        return distance;
    }
    
    
    
    
    var trimedClipMargins:CGPoint{
        //self.clipMargins
        var minRightMargin = CGFloat(self.bounds.width);
        var minLeftMargin = CGFloat(self.bounds.width);
        for v in self.subviews{
            if let busView = v as? SFAudioBusView{
                
                if busView.audioBus.mute == false{
                    
                    let rightMargin = busView.rightMargin;
                    if rightMargin < minRightMargin {
                        minRightMargin = rightMargin;
                    }
                    
                    let leftMargin = busView.leftMargin;
                    if leftMargin < minLeftMargin{
                        minLeftMargin = leftMargin;
                    }
                }
                
                
            }
        }
        //minRightMargin -= HAIRLINE_WIDTH;
        minRightMargin = max(0, minRightMargin);
        minRightMargin = min(self.bounds.width, minRightMargin);
        
        //minLeftMargin -= HAIRLINE_WIDTH;
        minLeftMargin = max(0,minLeftMargin);
        minLeftMargin = min(self.bounds.width,minLeftMargin);
        
        
        
        
        
        let newClipMargin = CGPoint(x:minLeftMargin,y:minRightMargin);
        return newClipMargin;
    }
    
    func stopPreview(){
        self.isUserInteractionEnabled = true;
        NSObject.cancelPreviousPerformRequests(withTarget: self);
        avPlayer?.pause();
        avPlayer = nil;
        self.previewDidFinish?();
        
    }
    
    func pausePreview(){
        avPlayer?.pause();
        NSObject.cancelPreviousPerformRequests(withTarget: self);
    }

    
    
    func resumePreviewAtPosition(seekTime:TimeInterval){
        let startTime = self.clipedMixRange.0 + seekTime;
        self.avPlayer?.seek(to: CMTime(seconds: startTime, preferredTimescale: 1));
        self.playingBeginTime = Date.timeIntervalSinceReferenceDate - seekTime;
        self.avPlayer?.play();
        self.perform(#selector(self.stopPreview), with: nil, afterDelay: self.clipedMixRange.1 - seekTime);
    }
    
    
    
    var passedTimeSincePlaying:TimeInterval?{
        if let beginTime = self.playingBeginTime {
            return Date.timeIntervalSinceReferenceDate - beginTime;
        }
        return nil;
    }
    
    func previewMixedAudio(completion: @escaping (Void)->Void){
        
        self.previewDidFinish = completion;
        
        if let (audioMixer,composition)  = self.createAudioMixerAndComposition() {
            
            let playItem = AVPlayerItem(asset: composition);
            playItem.audioMix = audioMixer;
            let avPlayer = AVPlayer(playerItem: playItem);
            
            self.avPlayer = avPlayer;
            
            avPlayer.play();
          
            
            let range = self.clipedMixRange;
            avPlayer.seek(to: CMTime(seconds: range.0, preferredTimescale: 1));
            self.playingBeginTime = Date.timeIntervalSinceReferenceDate;
            
            self.perform(#selector(self.stopPreview), with: nil, afterDelay: range.1);
            
            self.isUserInteractionEnabled = false;
            
            
        }
        
        
        
        
        
    }
    
    
    
}
