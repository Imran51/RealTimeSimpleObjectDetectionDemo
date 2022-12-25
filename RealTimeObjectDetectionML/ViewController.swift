//
//  ViewController.swift
//  RealTimeObjectDetectionML
//
//  Created by Imran Sayeed on 12/25/22.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    @IBOutlet weak var capturedView: UIView!
    
    @IBOutlet weak var captureToggleButton: UIButton!
    
    @IBOutlet weak var capturedObjectLabel: UILabel!
    
    private var session: AVCaptureSession = AVCaptureSession()
    private var device: AVCaptureDevice?
    private var input: AVCaptureDeviceInput?
    private var prevLayer: AVCaptureVideoPreviewLayer?
    private var isStartedCapturing = false
    private var queue = DispatchQueue(label: "imageRecognition.queue")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        createSession()
        capturedObjectLabel.alpha = 0
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        prevLayer?.frame.size = capturedView.frame.size
    }
    
    func createSession() {
        session = AVCaptureSession()
        session.sessionPreset = .photo
        device = AVCaptureDevice.default(for: AVMediaType.video)
        guard let device = device else { return }
        do{
            input = try AVCaptureDeviceInput(device: device)
        }
        catch{
            print(error)
        }
        
        if let input = input{
            session.addInput(input)
        }
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: queue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        session.addOutput(videoOutput)
        
        
        prevLayer = AVCaptureVideoPreviewLayer(session: session)
        prevLayer?.frame.size = capturedView.frame.size
        prevLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        prevLayer?.connection?.videoOrientation = .portrait
        guard let prevLayer = prevLayer else {
            return
        }
        capturedView.layer.insertSublayer(prevLayer, at: 0)
    }
    
    func cameraWithPosition(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera, .builtInTelephotoCamera, .builtInTrueDepthCamera, .builtInWideAngleCamera, ], mediaType: .video, position: position)
        
        if let device = deviceDiscoverySession.devices.first {
            return device
        }
        return nil
    }
    
    @IBAction func toggleCapture(_ sender: Any) {
        isStartedCapturing = !isStartedCapturing
        if isStartedCapturing {
            capturedObjectLabel.alpha = 1
            captureToggleButton.setTitle("Stop Capture", for: .normal)
            captureToggleButton.backgroundColor = .red
            DispatchQueue.global(qos: .background).async {[weak self] in
                self?.session.startRunning()
            }
            
        } else {
            capturedObjectLabel.alpha = 0
            captureToggleButton.setTitle("Start Capture", for: .normal)
            captureToggleButton.backgroundColor = .green
            DispatchQueue.global(qos: .background).async {[weak self] in
                self?.session.stopRunning()
            }
        }
    }
    
    
    @IBAction func toggleCamera(_ sender: Any) {
        let currentCameraInput: AVCaptureInput = session.inputs[0]
        session.removeInput(currentCameraInput)
        var newCamera: AVCaptureDevice
        if (currentCameraInput as! AVCaptureDeviceInput).device.position == .back {
            newCamera = self.cameraWithPosition(position: .front)!
        } else {
            newCamera = self.cameraWithPosition(position: .back)!
        }
        
        var newVideoInput: AVCaptureDeviceInput?
        do{
            newVideoInput = try AVCaptureDeviceInput(device: newCamera)
        }
        catch{
            print(error)
        }
        
        if let newVideoInput = newVideoInput{
            session.addInput(newVideoInput)
        }
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        connection.videoOrientation = .portrait
        
        // Resize the frame to 224x224
        // This is the required size of the inceptionv3 model
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let image = UIImage(ciImage: ciImage)
        
        UIGraphicsBeginImageContext(CGSize(width: 224, height: 224))
        image.draw(in: CGRect(x: 0, y: 0, width: 224, height: 224))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
    }
}
