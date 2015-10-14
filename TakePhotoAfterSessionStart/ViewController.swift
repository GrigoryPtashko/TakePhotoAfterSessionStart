//
//  ViewController.swift
//  TakePhotoAfterSessionStart
//
//  Created by Grigory Ptashko on 14.10.15.
//  Copyright © 2015 Grigory Ptashko. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    let session = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer!
    var cameraView: UIView!
    var stillCamOutput: AVCaptureStillImageOutput!
    var connection: AVCaptureConnection!

    override func viewDidLoad() {
        super.viewDidLoad()

        cameraView = UIView()
        cameraView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cameraView)
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[cv]-0-|", options: [],
            metrics: nil, views: ["cv": cameraView]))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[cv]-0-|", options: [],
            metrics: nil, views: ["cv": cameraView]))

        // "take photo" button
        let shootButton = UIButton()
        shootButton.backgroundColor = UIColor.redColor()
        shootButton.setTitle("start session and immediately take a photo", forState: .Normal)
        shootButton.addTarget(self, action: "takePhotoWithStartSession", forControlEvents: .TouchUpInside)
        shootButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(shootButton)
        view.addConstraint(NSLayoutConstraint(item: shootButton, attribute: .Width, relatedBy: .Equal,
            toItem: view, attribute: .Width, multiplier: 1.0, constant: 0.0))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[sb]-0-|", options: [],
            metrics: nil, views: ["sb": shootButton]))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[sb(==100)]", options: [],
            metrics: nil, views: ["sb": shootButton]))

        // fully initialize the front camera without starting the session
        var frontCamaDev: AVCaptureDevice!
        let availableCameraDevices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
        for device in availableCameraDevices as! [AVCaptureDevice] {
            if device.position == .Front {
                frontCamaDev = device
            }
        }
        do {
            // connect input to session
            let frontCameraInput = try AVCaptureDeviceInput(device: frontCamaDev)
            if session.canAddInput(frontCameraInput) {
                session.addInput(frontCameraInput)
            }

            // camera auth
            let authorizationStatus = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
            switch authorizationStatus {
            case .NotDetermined:
                AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo,
                    completionHandler: { (granted: Bool) -> Void in
                        if granted {
                            NSLog("photo camera permission granted")
                        } else {
                            NSLog("photo camera permission denied. How are we gonna do our awesome photo sesh??!!")
                        }
                })
            case .Authorized:
                NSLog("photo camera authorized")
            case .Denied, .Restricted:
                NSLog("photo camera not authorized")
            }

            // connect output to session
            stillCamOutput = AVCaptureStillImageOutput()
            if session.canAddOutput(stillCamOutput) {
                session.addOutput(stillCamOutput)
            }

            connection = stillCamOutput.connectionWithMediaType(AVMediaTypeVideo)
            connection.videoOrientation =
                AVCaptureVideoOrientation(rawValue: UIDevice.currentDevice().orientation.rawValue)!

            previewLayer = AVCaptureVideoPreviewLayer(session: session)
            cameraView.layer.addSublayer(previewLayer)
        } catch {
            NSLog("error [\(error)]")
        }
    }

    func takePhotoWithStartSession() {
        session.startRunning()

        stillCamOutput.captureStillImageAsynchronouslyFromConnection(connection) {
            (imageDataSampleBuffer, error) -> Void in

            if error != nil {
                NSLog("error while capturing still image: \(error)")

                return
            }

            if let image = UIImage(data:
                AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer))
            {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
                NSLog("photo taken!")
            }
        }

    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        previewLayer.frame = cameraView.bounds
    }
}

