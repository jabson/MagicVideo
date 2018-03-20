//
//  CameraViewController.swift
//  MagicVideo
//
//  Created by jaba odishelashvili on 3/14/18.
//  Copyright © 2018 Jabson. All rights reserved.
//

import UIKit
import AVFoundation
import GLKit
import Photos

class CameraViewController: UIViewController {
    //MARK: IBOutlets
    @IBOutlet weak var recordButton: UIButton?
    @IBOutlet weak var cameraSwitchButton: UIButton?
    @IBOutlet weak var torchButton: UIButton?
    @IBOutlet weak var zoomPoint: UIButton!
    @IBOutlet weak var zoomBg: UIImageView!
    
    // MARK: Video Preview Objects
    private var videoPreviewView: GLKView?
    private var ciContext: CIContext?
    private var glContext: EAGLContext?
    private var videoPreviewViewBounds: CGRect?
    
    // MARK: Camera Input and Outputs Objects
    private var frontCameraDeviceInput: AVCaptureDeviceInput?
    private var backCameraDeviceInput: AVCaptureDeviceInput?
    private var audioDeviceInput: AVCaptureDeviceInput?
    private var videoDataOutput: AVCaptureVideoDataOutput?
    
    // MARK: Session Objects
    private var captureSession: AVCaptureSession?
    private var videoWriter: VideoWriter?
    
    //MARK: helper recording
    private var cvPixelBuffer: CVPixelBuffer?
    private var isCapturing = false
    private var isBackCameraActive = true
    private var orientation = UIInterfaceOrientation.portrait
    private var deviceZoomFactor: CGFloat = 1.0
    
    //MARK: helper zoom
    private var previousLocation = CGPoint.zero
    
    // MARK: Object Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override var shouldAutorotate: Bool {
        return isCapturing == false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.requestAccess(for: .video, completion: { (granted) in
            if granted {
                self.setupVideoPreviewView()
                self.setupCaptureSession()
            } else {
                self.showDeviceAccessAlert(for: .video)
            }
        })
        
        requestAccess(for: .audio) { (granted) in
            if granted == false {
                self.showDeviceAccessAlert(for: .audio)
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        orientation = UIApplication.shared.statusBarOrientation
        resizePreviewView()
    }
    
    // MARK: Setup
    func setupCaptureSession() {
        // fetch camera device inputs
        guard let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("Can't fetch front camera device")
            return
        }
        
        guard let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Can't fetch back camera device")
            return
        }
        
        guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
            print("Can't getch audio device")
            return
        }
        
        do {
            frontCameraDeviceInput = try AVCaptureDeviceInput(device: frontCameraDevice)
            backCameraDeviceInput = try AVCaptureDeviceInput(device: backCameraDevice)
        } catch {
            print("Unable to obtain video device input")
            return
        }
        
        audioDeviceInput = try? AVCaptureDeviceInput(device: audioDevice)
        
        // create the capture session
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .high
        
        // CoreImage wants BGRA pixel format
        let outputSettings: [String: Any] = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        
        // create and configure video data output
        videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput?.videoSettings = outputSettings
        let videoSessionQueue = DispatchQueue(label: Constants.QueueLabels.VideoSessionQueue)
        videoDataOutput?.setSampleBufferDelegate(self, queue: videoSessionQueue)
        videoDataOutput?.alwaysDiscardsLateVideoFrames = true
        
        // create and configure audio data output
        let audioDataOutput = AVCaptureAudioDataOutput()
        let audioSessionQueue = DispatchQueue(label: Constants.QueueLabels.AudioSessionQueue)
        audioDataOutput.setSampleBufferDelegate(self, queue: audioSessionQueue)
        
        // begin configure capture session
        captureSession?.beginConfiguration()
        
        // connect the video device input and video data output
        captureSession?.addInput(backCameraDeviceInput!)
        captureSession?.addOutput(videoDataOutput!)
        if let audioDeviceInput = audioDeviceInput {
            captureSession?.addInput(audioDeviceInput)
            captureSession?.addOutput(audioDataOutput)
        }
        captureSession?.commitConfiguration()
        
        // then start everything
        captureSession?.startRunning()
    }
    
    func setupVideoPreviewView() {
        glContext = EAGLContext(api: .openGLES2)
        if let eaglContext = glContext {
            videoPreviewView = GLKView(frame: self.view.bounds, context: eaglContext)
            ciContext = CIContext(eaglContext: eaglContext)
        }
        if let videoPreviewView = videoPreviewView {
            videoPreviewView.enableSetNeedsDisplay = false
            videoPreviewView.frame = self.view.bounds
            videoPreviewView.isUserInteractionEnabled = false
            
            self.view.addSubview(videoPreviewView)
            self.view.sendSubview(toBack: videoPreviewView)
        }
        
        resizePreviewView()
    }
    
    // MARK: Update
    func resizePreviewView() {
        guard let videoPreviewView =  videoPreviewView else {
            print("can't resize preview vide")
            return
        }
        
        videoPreviewView.frame = self.view.bounds
        videoPreviewView.bindDrawable()
        videoPreviewViewBounds = CGRect.zero
        videoPreviewViewBounds?.size.width = self.view.bounds.width * videoPreviewView.contentScaleFactor
        videoPreviewViewBounds?.size.height = self.view.bounds.height * videoPreviewView.contentScaleFactor
    }
    
    // MARK: User Interface
    @IBAction func switchCamera(_ sender: Any) {
        guard let captureSession = captureSession else {
            print("Can't switch camera, session is nil")
            return
        }
        
        guard let frontCameraDeviceInput = frontCameraDeviceInput else {
            print("Can't switch camera, frontCameraDeviceInput is nil")
            return
        }
        
        guard let backCameraDeviceInput = backCameraDeviceInput else {
            print("Can't switch camera, backCameraDeviceInput is nil")
            return
        }
        
        captureSession.beginConfiguration()
        //Change camera device inputs from back to front or opposite
        if captureSession.inputs.contains(frontCameraDeviceInput) == true {
            captureSession.removeInput(frontCameraDeviceInput)
            captureSession.addInput(backCameraDeviceInput)
            backCameraDeviceInput.device.videoZoomFactor = deviceZoomFactor
            isBackCameraActive = true
            self.torchButton?.isHidden = false
        } else if captureSession.inputs.contains(backCameraDeviceInput) == true {
            captureSession.removeInput(backCameraDeviceInput)
            captureSession.addInput(frontCameraDeviceInput)
            frontCameraDeviceInput.device.videoZoomFactor = deviceZoomFactor
            isBackCameraActive = false
            self.torchButton?.isHidden = true
        }
        
        //Commit all the configuration changes at once
        captureSession.commitConfiguration();
        
        // fix mirrored preview
        videoPreviewView?.transform = (videoPreviewView?.transform.scaledBy(x: -1, y: 1))!
        cvPixelBuffer = nil
    }
    
    @IBAction func torch(_ sender: Any) {
        guard let backDevice = backCameraDeviceInput?.device else {
            print("Can't find back device")
            return;
        }
        
        if backDevice.hasTorch == false || backDevice.isTorchAvailable == false {
            print("Can't turn on/off tourch")
            return;
        }
        
        do {
            try backDevice.lockForConfiguration()
            backDevice.torchMode = backDevice.torchMode == .on ? .off : .on;
            backDevice.unlockForConfiguration()
        } catch {
            print("Something went wrong")
        }
    }
    
    @IBAction func record(_ sender: Any) {
        var recordButtonImage: UIImage?
        if isCapturing {
            stopRecording()
            recordButtonImage = UIImage(named: "record")
        } else {
            startRecording()
            recordButtonImage = UIImage(named: "recording")
        }
        
        if let recordButtonImage = recordButtonImage {
            self.recordButton?.setImage(recordButtonImage, for: .normal)
        }
    }
    
    
    @IBAction func handlePanGestureRecognizer(_ panGestureRecognizer: UIPanGestureRecognizer) {
        let locationInView = panGestureRecognizer.location(in: self.view)
        
        switch panGestureRecognizer.state {
        case .began:
            previousLocation = locationInView
        case .changed:
            let zoomPointMaxAltitude = zoomBg.center.y + zoomBg.frame.size.height / 2 - zoomPoint.frame.size.height/2 + zoomPoint.imageEdgeInsets.top
            let zoomPointMinAltitude = zoomBg.center.y - zoomBg.frame.size.height / 2 + zoomPoint.frame.size.height/2 - zoomPoint.imageEdgeInsets.bottom
            let locationOffsetY = locationInView.y - previousLocation.y
            zoomPoint.center.y += locationOffsetY
            previousLocation = locationInView
            
            zoomPoint.center.y = min(zoomPointMaxAltitude, zoomPoint.center.y)
            zoomPoint.center.y = max(zoomPointMinAltitude, zoomPoint.center.y)
            
            let percent = 1 - (zoomPoint.center.y - zoomPointMinAltitude) / (zoomPointMaxAltitude - zoomPointMinAltitude)
            changeDeviceZoom(percent: percent)
        case .ended, .cancelled: break
        default: break
        }
    }
    
    func changeDeviceZoom(percent: CGFloat) {
        guard let backDevice = backCameraDeviceInput?.device else {
            print("Can't find back device")
            return;
        }
        
        guard let frontDevice = frontCameraDeviceInput?.device else {
            print("Can't find front device")
            return;
        }
        
        let device = isBackCameraActive ? backDevice : frontDevice
        
        let maxZoomFactor = min(frontDevice.activeFormat.videoMaxZoomFactor, backDevice.activeFormat.videoMaxZoomFactor)
        let minZoomFactor: CGFloat = 1
        deviceZoomFactor = maxZoomFactor * percent
        
        deviceZoomFactor = min(maxZoomFactor, deviceZoomFactor)
        deviceZoomFactor = max(minZoomFactor, deviceZoomFactor)
        
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = deviceZoomFactor
            device.unlockForConfiguration()
        } catch {
            print("Can't change zoom factor")
        }
    }
    
    //MARK: private methods
    private func startRecording() {
        if isCapturing == true {
            print("Can't start recording, already recording!")
            return
        }
        
        guard let videoDataOutput = videoDataOutput else {
            print("videoDataOutput is nil, can't create VideoWriter")
            return
        }
        
        guard let videoWidth = videoDataOutput.videoSettings["Width"] as? Int else  {
            print("Can't recognize video resolution, can't create VideoWriter")
            return
        }
        
        guard let videoHeight = videoDataOutput.videoSettings["Height"] as? Int else  {
            print("Can't recognize video resolution, can't create VideoWriter")
            return
        }
        
        let path = videofilePath()
        let videoURL = URL(fileURLWithPath: path)
        let fileManager = FileManager()
        
        if fileManager.fileExists(atPath: path) {
            do {
                try fileManager.removeItem(atPath: path)
            } catch {
                print("Can't remove file at path \(path) so can't create VideoWriter")
                return
            }
        }
        
        var size = CGSize(width: videoWidth, height: videoHeight)
        if UIInterfaceOrientationIsPortrait(UIApplication.shared.statusBarOrientation) {
            size = CGSize(width: videoHeight, height: videoWidth)
        }
        
        self.cameraSwitchButton?.isHidden = true
        self.torchButton?.isHidden = true
        
        self.videoWriter = VideoWriter(fileUrl: videoURL, size: size)
        self.isCapturing = true
    }
    
    private func stopRecording() {
        if isCapturing == false {
            print("Can't stop recording")
            return
        }
        
        guard let videoWriter = videoWriter else {
            print("Video writer is nil")
            return
        }
        
        self.isCapturing = false
        self.videoWriter?.markAsFinished()
        self.cameraSwitchButton?.isHidden = false
        if isBackCameraActive {
            self.torchButton?.isHidden = false
        }
        
        videoWriter.finish {
            self.videoWriter = nil
            self.cvPixelBuffer = nil
            let videoFilePath = self.videofilePath()

            self.requestPhotoLibraryAccess(completion: { (granted) in
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(fileURLWithPath: videoFilePath))
                }) { saved, error in
                    if saved == true {
                        print("Video saved to photo library")
                    } else {
                        print("Video did not save to photo library, reason- \(String(describing: error?.localizedDescription))")
                    }
                }
            })
        }
    }
    
    // request device access
    private func requestAccess(for mediaType: AVMediaType, completion: @escaping (Bool) -> Void ) {
        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: mediaType)
        switch authorizationStatus {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: mediaType, completionHandler: { (granted) in
                DispatchQueue.main.async {
                    completion(granted)
                }
            })
        case .authorized:
            completion(true)
        case .denied, .restricted:
            completion(false)
        }
    }
    
    private func requestPhotoLibraryAccess(completion: @escaping (Bool) -> Void ) {
        let authorizationStatus = PHPhotoLibrary.authorizationStatus()
        
        switch authorizationStatus {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ (status) in
                let granted = (status == .authorized)
                DispatchQueue.main.async {
                    completion(granted)
                }
            })
        case .authorized:
            completion(true)
        case .denied, .restricted:
            completion(false)
        }
    }
    
    // show device access denied alert, and redirect to settings if there is no access
    private func showDeviceAccessAlert(for mediaType: AVMediaType) {
        var alertTitle: String?
        var alertMessage: String?
        
        if mediaType == .video {
            alertTitle = Constants.AlertTitles.CameraAccess
            alertMessage = Constants.AlertMessages.CameraAccess
        } else if mediaType == .audio {
            alertTitle = Constants.AlertTitles.MicrophoneAccess
            alertMessage = Constants.AlertMessages.MicrophoneAccess
        } else {
            print("Unknown Media Type to show alert")
            return
        }
        
        let alertController = UIAlertController(title: alertTitle!, message: alertMessage!, preferredStyle: .alert)
        let okAction = UIAlertAction(title: Constants.AlertActionTitles.Ok, style: .default) { (action) in
            let settingsURL = URL(string: UIApplicationOpenSettingsURLString)
            if let url = settingsURL {
                UIApplication.shared.open(url, options: [:], completionHandler: nil);
            } else {
                print("Can't open application settings")
            }
        }
        let cancelAction = UIAlertAction(title: Constants.AlertActionTitles.Cancel, style: .cancel, handler: nil);
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    // get video file path
    private func videofilePath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths.first!
        let videoPath = "\(documentsDirectory)/video.mp4"
        
        return videoPath
    }
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    // MARK: AVCaptureVideoDataOutputSampleBufferDelegate
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if CMSampleBufferDataIsReady(sampleBuffer) == false {
            print("Sample buffer is not ready")
            return
        }
        
        if output is AVCaptureVideoDataOutput {
            videoOutput(output, didOutput: sampleBuffer, from: connection)
        }
        
        if output is AVCaptureAudioDataOutput {
            audioOutput(output, didOutput: sampleBuffer, from: connection)
        }
    }
    
    private func videoOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Can't create pixel buffer")
            return
        }
        
        guard let videoPreviewViewBounds = videoPreviewViewBounds else {
            print("Unrecognized preview bounds")
            return
        }
        
        var sourceImage = CIImage(cvImageBuffer: pixelBuffer)
        // fix video orientation issue
        if isBackCameraActive == true && orientation == .landscapeLeft {
            sourceImage = sourceImage.oriented(forExifOrientation: 3)
        } else if isBackCameraActive == false && orientation == .landscapeRight {
            sourceImage = sourceImage.oriented(forExifOrientation: 3)
        } else if orientation == .portrait {
            sourceImage = sourceImage.oriented(forExifOrientation: 6)
        }
        let sourceExtent = sourceImage.extent
        
        // add filter to image
        guard let filteredImage = sourceImage.invertColorEffect() else {
            print("Can't add filter ro image")
            return
        }
        
        let sourceAspect = sourceExtent.size.width / sourceExtent.size.height
        let previewAspect = videoPreviewViewBounds.size.width / videoPreviewViewBounds.size.height
        
        // we want to maintain the aspect radio of the screen size, so we clip the video image
        var drawRect = sourceExtent
        if sourceAspect > previewAspect {
            // use full height of the video image, and center crop the width
            drawRect.origin.x += (drawRect.size.width - drawRect.size.height * previewAspect) / 2.0
            drawRect.size.width = drawRect.size.height * previewAspect
        } else {
            // use full width of the video image, and center crop the height
            drawRect.origin.y += (drawRect.size.height - drawRect.size.width / previewAspect) / 2.0
            drawRect.size.height = drawRect.size.width / previewAspect
        }
        
        videoPreviewView?.bindDrawable()
        if glContext != EAGLContext.current() {
            EAGLContext.setCurrent(glContext)
        }
        
        // clear eagl view to grey
        glClearColor(0.5, 0.5, 0.5, 1.0);
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT));
        
        // set the blend mode to "source over" so that CI will use that
        glEnable(GLenum(GL_BLEND));
        glBlendFunc(GLenum(GL_ONE), GLenum(GL_ONE_MINUS_SRC_ALPHA));
        
        ciContext?.draw(filteredImage, in: videoPreviewViewBounds, from: drawRect)
        videoPreviewView?.display()
        
        //recording
        if isCapturing {
            // convert CIImage to CVPixelBuffer
            if cvPixelBuffer == nil {
                let attributesDictionary = [kCVPixelBufferIOSurfacePropertiesKey: [:]]
                CVPixelBufferCreate(kCFAllocatorDefault,
                                    Int(sourceImage.extent.size.width),
                                    Int(sourceImage.extent.size.height),
                                    kCVPixelFormatType_32BGRA,
                                    attributesDictionary as CFDictionary,
                                    &cvPixelBuffer);
            }
            ciContext?.render(filteredImage, to: cvPixelBuffer!)
            
            // convert new CVPixelBuffer to new CMSampleBuffer
            var sampleTime = CMSampleTimingInfo()
            sampleTime.duration = CMSampleBufferGetDuration(sampleBuffer)
            sampleTime.presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            sampleTime.decodeTimeStamp = CMSampleBufferGetDecodeTimeStamp(sampleBuffer)
            
            var videoInfo: CMVideoFormatDescription? = nil
            CMVideoFormatDescriptionCreateForImageBuffer(kCFAllocatorDefault, cvPixelBuffer!, &videoInfo)
            var newSampleBuffer: CMSampleBuffer?
            CMSampleBufferCreateReadyWithImageBuffer(kCFAllocatorDefault, cvPixelBuffer!, videoInfo!, &sampleTime, &newSampleBuffer)
            
            // writer new CMSampleBuffer to asser writer
            self.videoWriter?.write(sample: newSampleBuffer!, isVideoBuffer: true)
        }
    }
    
    private func audioOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        //recording
        if isCapturing {
            self.videoWriter?.write(sample: sampleBuffer, isVideoBuffer: false)
        }
    }
}
