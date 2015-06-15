//
//  DetailViewController.swift
//  iCashSG 2
//
//  Created by Mugunth on 15/5/15.
//  Copyright (c) 2015 Steinlogic Consulting and Training Pte Ltd. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

  @IBOutlet weak var fullScreenImageView: UIImageView!


  var detailItem: FlickrImage? {
    didSet {
      // Update the view.
      self.configureView()
    }
  }

  func configureView() {
    // Update the user interface for the detail item.
    if let detail: FlickrImage = self.detailItem {

      let client = (UIApplication.sharedApplication().delegate as! AppDelegate).host
      client?.fetchImage(detail.fullscreenImageUrlString!) { (image : UIImage?) -> Void in

        dispatch_async(dispatch_get_main_queue()) { () -> Void in

          UIView.transitionWithView(self.view!, duration: 0.5, options: .TransitionCrossDissolve, animations: {
            () -> Void in
            self.fullScreenImageView.image = image;
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

