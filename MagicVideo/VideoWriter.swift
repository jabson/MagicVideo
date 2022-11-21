//
//  VideoWriter.swift
//  MagicVideo
//
//  Created by jaba odishelashvili on 3/19/18.
//  Copyright © 2018 Jabson. All rights reserved.
//

import UIKit
import AVFoundation

class VideoWriter: NSObject {
    var fileWriter: AVAssetWriter
    var videoInput: AVAssetWriterInput
    var audioInput: AVAssetWriterInput
    
    
    private var isFirstVideoFrame = true
    
    init(fileUrl: URL, size: CGSize) {
        fileWriter = try! AVAssetWriter(outputURL: fileUrl as URL, fileType: .mov)
        
        let videoOutputSettings: Dictionary<String, AnyObject> = [
            AVVideoCodecKey : AVVideoCodecH264 as AnyObject,
            AVVideoWidthKey : size.width as AnyObject,
            AVVideoHeightKey : size.height as AnyObject
        ];
        
        videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoOutputSettings)
        videoInput.expectsMediaDataInRealTime = true
        fileWriter.add(videoInput)
        
        let audioOutputSettings: Dictionary<String, AnyObject> = [
            AVFormatIDKey : Int(kAudioFormatMPEG4AAC) as AnyObject,
            AVNumberOfChannelsKey : 1 as AnyObject,
            AVSampleRateKey : 44100.0 as AnyObject,
            AVEncoderBitRateKey : 128000 as AnyObject
        ]
        audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioOutputSettings)
        audioInput.expectsMediaDataInRealTime = true
        fileWriter.add(audioInput)
        
        fileWriter.startWriting()
    }
    
    func write(sample: CMSampleBuffer, isVideoBuffer: Bool){
        if fileWriter.status == .failed {
            let failedReason = fileWriter.error?.localizedDescription ?? "Unknown"
            print("Failed writing reason - " + failedReason)
            return
        }
        
        if videoInput.isReadyForMoreMediaData == false {
            print("Video input is not yet ready to write")
            return
        }
        
        if audioInput.isReadyForMoreMediaData == false {
            print("Audio input is not yet ready to write")
            return
        }
        
        // here we start recording with video buffer, this fix black frame
        if fileWriter.status == .writing && isFirstVideoFrame == true && isVideoBuffer {
            isFirstVideoFrame = false;
            let startTime = CMSampleBufferGetPresentationTimeStamp(sample)
            fileWriter.startSession(atSourceTime: startTime)
        }
        
        if isFirstVideoFrame == false {
            if isVideoBuffer {
                videoInput.append(sample)
            } else {
                audioInput.append(sample)
            }
        }
    }
    
    func markAsFinished() {
        videoInput.markAsFinished()
        audioInput.markAsFinished()
    }
    
    func finish(completion: @escaping () -> Void){
        fileWriter.finishWriting {
             DispatchQueue.main.async {
                completion()
            }
        }
    }
}
