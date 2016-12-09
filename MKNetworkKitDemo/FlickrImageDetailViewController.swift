//
//  FlickrImageDetailViewController.swift
//  MKNetworkKit
//
//  Created by Mugunth on 15/5/15.
//  Copyright (c) 2015 Steinlogic Consulting and Training Pte Ltd. All rights reserved.
//

import UIKit

class FlickrImageDetailViewController: UIViewController {

  @IBOutlet weak var fullScreenImageView: UIImageView!


  var detailItem: FlickrImage? {
    didSet {
      // Update the view.
      self.configureView()
    }
  }

  var flickrHost: FlickrClient {
    return (UIApplication.shared.delegate as! AppDelegate).flickrHost
  }

  func configureView() {
    // Update the user interface for the detail item.
    if let detail: FlickrImage = self.detailItem {

      flickrHost.fetchImage(detail.fullscreenImageUrlString!) { (image : UIImage?) -> Void in

        DispatchQueue.main.async { () -> Void in

          UIView.transition(with: self.view!, duration: 0.5, options: .transitionCrossDissolve, animations: {
            () -> Void in
            self.fullScreenImageView.image = image
            }, completion: nil)
        }
      }
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    self.configureView()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  
}

