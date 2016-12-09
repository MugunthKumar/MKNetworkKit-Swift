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
      uploadButton.isEnabled = (imageFilePath != nil)
    }
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    uploadButton.isEnabled = false
    // Do any additional setup after loading the view.
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  @IBAction func chooseAction(_ sender: AnyObject) {
    let imagePickerController = UIImagePickerController()
    imagePickerController.delegate = self
    imagePickerController.sourceType = .photoLibrary
    present(imagePickerController, animated: true, completion: nil)
  }

  var host: HTTPBinHost {
    return (UIApplication.shared.delegate as! AppDelegate).httpbinHost
  }

  @IBAction func uploadAction(_ sender: AnyObject) {
    host.uploadImage(imageFilePath!) {

    }
  }

  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    let image = info[UIImagePickerControllerOriginalImage] as! UIImage
    imageView.image = image
    let size = CGSize(width: 250, height: 250)
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
    image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
    let smallImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    imageFilePath = NSTemporaryDirectory() + "image.png"
    let url = URL(fileURLWithPath: imageFilePath!)
    try? UIImageJPEGRepresentation(smallImage!, 0.8)?.write(to: url, options: .atomicWrite)
    dismiss(animated: true, completion: nil)
  }

  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    dismiss(animated: true, completion: nil)
  }

}
