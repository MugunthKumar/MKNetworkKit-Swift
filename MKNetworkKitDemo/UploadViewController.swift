//
//  UploadViewController.swift
//  MKNetworkKitDemo
//
//  Created by Mugunth Kumar on Feb 9 2016.
//  Copyright © 2016 Steinlogic Consulting and Training Pte Ltd. All rights reserved.
//

import UIKit

class UploadViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

  @IBOutlet var imageView: UIImageView!
  @IBOutlet var uploadButton: UIButton!
  var imageFilePath: String? {
    didSet {
      uploadButton.enabled = (imageFilePath != nil)
    }
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    uploadButton.enabled = false
    // Do any additional setup after loading the view.
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  @IBAction func chooseAction(sender: AnyObject) {
    let imagePickerController = UIImagePickerController()
    imagePickerController.delegate = self
    imagePickerController.sourceType = .PhotoLibrary
    presentViewController(imagePickerController, animated: true, completion: nil)
  }

  var testHost: TestClient {
    return (UIApplication.sharedApplication().delegate as! AppDelegate).testHost
  }

  @IBAction func uploadAction(sender: AnyObject) {
    testHost.uploadImage(imageFilePath!) {

    }
  }

  func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
    let image = info[UIImagePickerControllerOriginalImage] as! UIImage
    imageView.image = image
    imageFilePath = NSTemporaryDirectory() + "image.png"
    UIImageJPEGRepresentation(image, 0.8)?.writeToFile(imageFilePath!, atomically: true)
    dismissViewControllerAnimated(true, completion: nil)
  }

  func imagePickerControllerDidCancel(picker: UIImagePickerController) {
    dismissViewControllerAnimated(true, completion: nil)
  }

}
