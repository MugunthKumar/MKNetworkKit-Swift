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
    return (UIApplication.shared.delegate as! AppDelegate).flickrHost
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    progressView.alpha = 0
  }

  @IBAction func downloadPauseResumeButtonAction(_ sender: AnyObject) {

    if let unwrappedRequest = request {
      if unwrappedRequest.state == .Paused {
        unwrappedRequest.resume()
        downloadPauseResumeButton.setTitle("Pause", for: UIControlState())
      } else {
        unwrappedRequest.pause()
        downloadPauseResumeButton.setTitle("Resume", for: UIControlState())
      }
    } else {
      downloadPauseResumeButton.setTitle("Pause", for: UIControlState())
      progressView.alpha = 1
      request = flickrHost.request(withAbsoluteURLString:textField.text!)
      let path = "\(NSHomeDirectory())/image.jpg"
//      if let outputStream = NSOutputStream(toFileAtPath: path, append: true) {
//        request?.appendOutputStream(outputStream)
//      }
      request?.downloadPath = path
      if FileManager.default.fileExists(atPath: path) {
        do {
          try FileManager.default.removeItem(atPath: path)
        } catch let error as NSError {
          print (error)
        }
      }
      request?.progress { inProgressRequest in
        DispatchQueue.main.async {
          self.progressView.progress = Float(inProgressRequest.progressValue!)
        }
        }.completion { completedRequest in
          DispatchQueue.main.async {
            self.progressView.alpha = 0
            self.downloadPauseResumeButton.setTitle("Download", for: .normal)
            self.request = nil
          }
          if let error = completedRequest.error {
            print ("Error \(error)")
          } else {
            DispatchQueue.main.async {
              self.presentFile(path)
            }
          }
        }.run()
    }
  }

  func presentFile(_ fileUrl: String) {
    let controller = UIDocumentInteractionController(url: URL(fileURLWithPath: fileUrl))
    controller.delegate = self
    controller.presentPreview(animated: true)
  }

  func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
    return self
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
}
