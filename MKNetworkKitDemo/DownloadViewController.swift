//
//  DownloadViewController.swift
//  MKNetworkKitDemo
//
//  Created by Mugunth Kumar on Feb 12 2016.
//  Copyright © 2016 Steinlogic Consulting and Training Pte Ltd. All rights reserved.
//

import UIKit
import MKNetworkKit

class DownloadViewController: UIViewController, UIDocumentInteractionControllerDelegate {

  @IBOutlet var downloadPauseResumeButton: UIButton!
  @IBOutlet var textField: UITextField!
  @IBOutlet var progressView: UIProgressView!

  var request: Request?

  var flickrHost: FlickrClient {
    return (UIApplication.sharedApplication().delegate as! AppDelegate).flickrHost
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    progressView.alpha = 0
  }

  @IBAction func downloadPauseResumeButtonAction(sender: AnyObject) {

    if let unwrappedRequest = request {
      if unwrappedRequest.state == .Paused {
        unwrappedRequest.resume()
        downloadPauseResumeButton.setTitle("Pause", forState: .Normal)
      } else {
        unwrappedRequest.pause()
        downloadPauseResumeButton.setTitle("Resume", forState: .Normal)
      }
    } else {
      downloadPauseResumeButton.setTitle("Pause", forState: .Normal)
      progressView.alpha = 1
      request = flickrHost.request(withUrlString:textField.text!)
      let path = "\(NSHomeDirectory())/image.jpg"
      request?.downloadPath = path
      do {
        try NSFileManager.defaultManager().removeItemAtPath(path)
      } catch let error as NSError {
        print (error)
      }
      request?.progress { inProgressRequest in
        dispatch_async(dispatch_get_main_queue()) {
          self.progressView.progress = Float(inProgressRequest.progressValue!)
        }
        }.completion { completedRequest in
          dispatch_async(dispatch_get_main_queue()) {
            self.progressView.alpha = 0
            self.downloadPauseResumeButton.setTitle("Download", forState: .Normal)
            self.request = nil
          }
          if let error = completedRequest.error {
            print ("Error \(error)")
          } else {
            dispatch_async(dispatch_get_main_queue()) {
              self.presentFile(completedRequest.downloadPath!)
            }
          }
        }.run()
    }
  }

  func presentFile(fileUrl: String) {
    let controller = UIDocumentInteractionController(URL: NSURL(fileURLWithPath: fileUrl))
    controller.delegate = self
    controller.presentPreviewAnimated(true)
  }

  func documentInteractionControllerViewControllerForPreview(controller: UIDocumentInteractionController) -> UIViewController {
    return self
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
}
