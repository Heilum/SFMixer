//
//  SFAudioWaveformHelper.swift from :https://github.com/JagieChen/SFAudioWaveformHelper
//  
//
//  Created by CHENWANFEI on 12/03/2017.
//  Copyright © 2017 SwordFish. All rights reserved.

//   references: 1. http://www.davidstarke.com/2015/04/waveforms.html
//               2. https://github.com/fulldecent/FDWaveformView

//

import UIKit
import MediaPlayer
import AVFoundation
import Accelerate

fileprivate let noiseFloor: CGFloat = -50.0

func generateWaveformImage(audioURL:URL, imageSizeInPixel:CGSize, waveColor:UIColor, completion:@escaping (_ waveformImage:UIImage?)->Void){
    let asset = AVURLAsset(url: audioURL, options: [AVURLAssetPreferPreciseDurationAndTimingKey: NSNumber(value: true as Bool)])
    
    
    guard let assetTrack = asset.tracks(withMediaType: AVMediaTypeAudio).first else {
        NSLog("FDWaveformView failed to load AVAssetTrack")
        callCompletion(image: nil,completion: completion);
        return
    }
    
    asset.loadValuesAsynchronously(forKeys: ["duration"]) {
        var error: NSError?
        let status = asset.statusOfValue(forKey: "duration", error: &error)
        switch status {
        case .loaded:
            if let audioFormatDesc = assetTrack.formatDescriptions.first {
                let item = audioFormatDesc as! CMAudioFormatDescription     // TODO: Can this be safer?
                if let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(item) {
                    let numOfTotalSamples = (asbd.pointee.mSampleRate) * Float64(asset.duration.value) / Float64(asset.duration.timescale)
                    
                    
                    guard let reader = try? AVAssetReader(asset: asset) else {
                        completion(nil);
                        return
                    }
                    
                    reader.timeRange = CMTimeRange(start: CMTime(value: Int64(0), timescale: asset.duration.timescale), duration: CMTime(value: Int64(numOfTotalSamples), timescale: asset.duration.timescale))
                    let outputSettingsDict: [String : Any] = [
                        AVFormatIDKey: Int(kAudioFormatLinearPCM),
                        AVLinearPCMBitDepthKey: 16,
                        AVLinearPCMIsBigEndianKey: false,
                        AVLinearPCMIsFloatKey: false,
                        AVLinearPCMIsNonInterleaved: false
                    ]
                    
                    let readerOutput = AVAssetReaderTrackOutput(track: assetTrack, outputSettings: outputSettingsDict)
                    readerOutput.alwaysCopiesSampleData = false
                    reader.add(readerOutput)
                    
                    var channelCount = 1
                    
                    let formatDesc = assetTrack.formatDescriptions
                    for item in formatDesc {
                        guard let fmtDesc = CMAudioFormatDescriptionGetStreamBasicDescription(item as! CMAudioFormatDescription) else { continue }    // TODO: Can the forced downcast in here be safer?
                        channelCount = Int(fmtDesc.pointee.mChannelsPerFrame)
                    }
                    
                    var sampleMax = noiseFloor
                    
                    let widthInPixels = Int(imageSizeInPixel.width)
                    let samplesPerPixel = max(1,  channelCount * Int(numOfTotalSamples) / widthInPixels)
                    let filter = [Float](repeating: 1.0 / Float(samplesPerPixel), count: samplesPerPixel)
                    
                    var outputSamples = [CGFloat]()
                    var sampleBuffer = Data()
                    
                    // 16-bit samples
                    reader.startReading()
                    
                    while reader.status == .reading {
                        guard let readSampleBuffer = readerOutput.copyNextSampleBuffer(),
                            let readBuffer = CMSampleBufferGetDataBuffer(readSampleBuffer) else {
                                break
                        }
                        
                        // Append audio sample buffer into our current sample buffer
                        var readBufferLength = 0
                        var readBufferPointer: UnsafeMutablePointer<Int8>?
                        CMBlockBufferGetDataPointer(readBuffer, 0, &readBufferLength, nil, &readBufferPointer)
                        sampleBuffer.append(UnsafeBufferPointer(start: readBufferPointer, count: readBufferLength))
                        CMSampleBufferInvalidate(readSampleBuffer)
                        
                        let totalSamples = sampleBuffer.count / MemoryLayout<Int16>.size
                        let downSampledLength = totalSamples / samplesPerPixel
                        let samplesToProcess = downSampledLength * samplesPerPixel
                        
                        guard samplesToProcess > 0 else { continue }
                        
                        processSamples(fromData: &sampleBuffer,
                                       sampleMax: &sampleMax,
                                       outputSamples: &outputSamples,
                                       samplesToProcess: samplesToProcess,
                                       downSampledLength: downSampledLength,
                                       samplesPerPixel: samplesPerPixel,
                                       filter: filter)
                    }
                    
                    // Process the remaining samples at the end which didn't fit into samplesPerPixel
                    let samplesToProcess = sampleBuffer.count / MemoryLayout<Int16>.size
                    if samplesToProcess > 0 {
                        let downSampledLength = 1
                        let samplesPerPixel = samplesToProcess
                        
                        let filter = [Float](repeating: 1.0 / Float(samplesPerPixel), count: samplesPerPixel)
                        
                        processSamples(fromData: &sampleBuffer,
                                       sampleMax: &sampleMax,
                                       outputSamples: &outputSamples,
                                       samplesToProcess: samplesToProcess,
                                       downSampledLength: downSampledLength,
                                       samplesPerPixel: samplesPerPixel,
                                       filter: filter)
                    }
                    
                    if reader.status == .completed {
                        let image =  plotLogGraph(outputSamples, maximumValue: sampleMax, zeroValue: noiseFloor, imageHeight: imageSizeInPixel.height, color:waveColor );
                        
                        callCompletion(image: image,completion: completion);
                    } else {
                        callCompletion(image: nil,completion: completion);
                    }
                    
                    
                }
            }
        case .failed, .cancelled, .loading, .unknown:
            callCompletion(image: nil,completion: completion);
        }
    }
    
}


private func callCompletion(image:UIImage?,completion: @escaping (_ waveformImage:UIImage?)->Void){
    DispatchQueue.main.async {
        completion(image);
    }
}

private func processSamples(fromData sampleBuffer: inout Data, sampleMax: inout CGFloat, outputSamples: inout [CGFloat], samplesToProcess: Int, downSampledLength: Int, samplesPerPixel: Int, filter: [Float]) {
    sampleBuffer.withUnsafeBytes { (samples: UnsafePointer<Int16>) in
        
        var processingBuffer = [Float](repeating: 0.0, count: samplesToProcess)
        
        let sampleCount = vDSP_Length(samplesToProcess)
        
        //Convert 16bit int samples to floats
        vDSP_vflt16(samples, 1, &processingBuffer, 1, sampleCount)
        
        //Take the absolute values to get amplitude
        vDSP_vabs(processingBuffer, 1, &processingBuffer, 1, sampleCount)
        
        //Convert to dB
        var zero: Float = 32768.0
        vDSP_vdbcon(processingBuffer, 1, &zero, &processingBuffer, 1, sampleCount, 1)
        
        //Clip to [noiseFloor, 0]
        var ceil: Float = 0.0
        var noiseFloorFloat = Float(noiseFloor)
        vDSP_vclip(processingBuffer, 1, &noiseFloorFloat, &ceil, &processingBuffer, 1, sampleCount)
        
        //Downsample and average
        var downSampledData = [Float](repeating: 0.0, count: downSampledLength)
        vDSP_desamp(processingBuffer,
                    vDSP_Stride(samplesPerPixel),
                    filter, &downSampledData,
                    vDSP_Length(downSampledLength),
                    vDSP_Length(samplesPerPixel))
        
        let downSampledDataCG = downSampledData.map { (value: Float) -> CGFloat in
            let element = CGFloat(value)
            if element > sampleMax { sampleMax = element }
            return element
        }
        
        // Remove processed samples
        sampleBuffer.removeFirst(samplesToProcess * MemoryLayout<Int16>.size)
        outputSamples += downSampledDataCG
    }
}

private func plotLogGraph(_ samples: [CGFloat], maximumValue max: CGFloat, zeroValue min: CGFloat, imageHeight: CGFloat,color:UIColor) -> UIImage? {
    let imageSize = CGSize(width: CGFloat(samples.count), height: imageHeight)
    UIGraphicsBeginImageContext(imageSize)
    guard let context = UIGraphicsGetCurrentContext() else {
        return nil
    }
    
    context.setAlpha(1.0)
    context.setLineWidth(1.0)
    context.setStrokeColor(color.cgColor)
    
    let sampleDrawingScale: CGFloat
    if max == min {
        sampleDrawingScale = 0
    } else {
        sampleDrawingScale = imageHeight / 2 / (max - min)
    }
    let verticalMiddle = imageHeight / 2
    for (x, sample) in samples.enumerated() {
        let height = (sample - min) * sampleDrawingScale
        context.move(to: CGPoint(x: CGFloat(x), y: verticalMiddle - height))
        context.addLine(to: CGPoint(x: CGFloat(x), y: verticalMiddle + height))
        context.strokePath();
    }
    guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
        return nil;
    }
    
    UIGraphicsEndImageContext()
    return image;
}


