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

  var host: HTTPBinHost {
    return (UIApplication.sharedApplication().delegate as! AppDelegate).httpbinHost
  }

  @IBAction func uploadAction(sender: AnyObject) {
    host.uploadImage(imageFilePath!) {

    }
  }

  func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
    let image = info[UIImagePickerControllerOriginalImage] as! UIImage
    imageView.image = image
    let size = CGSizeMake(250, 250)
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
    image.drawInRect(CGRectMake(0, 0, size.width, size.height))
    let smallImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    imageFilePath = NSTemporaryDirectory() + "image.png"
    UIImageJPEGRepresentation(smallImage, 0.8)?.writeToFile(imageFilePath!, atomically: true)
    dismissViewControllerAnimated(true, completion: nil)
  }

  func imagePickerControllerDidCancel(picker: UIImagePickerController) {
    dismissViewControllerAnimated(true, completion: nil)
  }

}
