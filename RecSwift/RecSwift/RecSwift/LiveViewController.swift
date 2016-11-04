//
//  LiveViewController.swift
//  RecSwift
//
//  Created by FromF on 2016/11/04.
//  Copyright © 2016年 Personal. All rights reserved.
//

import UIKit

class LiveViewController: UIViewController , OLYCameraLiveViewDelegate {
    
    // OLYCameraKit Instance
    let camera = AppDelegate.sharedCamera

    // Image UI
    @IBOutlet weak var liveViewImage: UIImageView!
    
    // Button UI
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var shutterButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if connectOPC() == false {
            dismiss(animated: true, completion: nil)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Button Action
    @IBAction func closeButtonAction(_ sender: Any) {
        dissconnectOPC()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func shutterButtonAction(_ sender: Any) {
        let globalQueue = DispatchQueue.global()
        let mainQueue = DispatchQueue.main
        
        globalQueue.async {
            mainQueue.async {
                self.shutterButton.isEnabled = false
            }
            
            if self.takePictureOPC() == false {
                print("Failed Take Picture")
            }
            
            mainQueue.async {
                self.shutterButton.isEnabled = true
            }
        }
    }
    
    // MARK: - Access OLYCameraKit
    func connectOPC() -> Bool {
        var result : Bool = true
        do {
            //Connect Camera
            try camera.connect(OLYCameraConnectionTypeWiFi)
            
            //Disable Auto Start LiveView
            camera.autoStartLiveView = false
            
            //Change Recoding Mode
            try camera.changeRunMode(OLYCameraRunModeRecording)
            
            //CameraProperty Settings
            let propertyDictionary:[String : String] = [
                "TAKEMODE"  :   "<TAKEMODE/P>",
                "TAKE_DRIVE":   "<TAKE_DRIVE/DRIVE_NORMAL>",
                "RECVIEW"   :   "<RECVIEW/OFF>",
                "COLORTONE" :   "<COLORTONE/NATURAL>",
                ]
            try camera.setCameraPropertyValues(propertyDictionary)
            
            //Set LiveView size VGA
            try camera.changeLiveViewSize(OLYCameraLiveViewSizeVGA)
            
            //Start LiveView
            try camera.startLiveView()
            
            //LiveView Delegate set
            camera.liveViewDelegate = self
        } catch _ {
            result = false
        }
        
        return result;
    }
    
    func dissconnectOPC() {
        do {
            try camera.disconnect(withPowerOff: false)
        } catch _ {
            // None
        }
    }
    
    func takePictureOPC() -> Bool {
        var result : Bool = true
        let semaphore = DispatchSemaphore(value: 0);

        camera.takePicture(nil, progressHandler: nil, completionHandler:{info -> Void in
            semaphore.signal()
            print("Complete")
        }, errorHandler: {error -> Void in
            semaphore.signal()
            print("Error")
            result = false
        })
        semaphore.wait()
        
        return result;
    }
    
    // MARK: - LiveView Update
    func camera(_ camera: OLYCamera!, didUpdateLiveView data: Data!, metadata: [AnyHashable : Any]!) {
        let liveImage = OLYCameraConvertDataToImage(data, metadata)
        liveViewImage.image = liveImage
    }
}
