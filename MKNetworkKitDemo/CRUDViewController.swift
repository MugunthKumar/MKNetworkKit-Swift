//
//  CRUDViewController.swift
//  MKNetworkKitDemo
//
//  Created by Mugunth Kumar on Feb 12 2016.
//  Copyright © 2016 Steinlogic Consulting and Training Pte Ltd. All rights reserved.
//

import UIKit
import MKNetworkKit

class CRUDViewController: UIViewController {

  var method: HTTPMethod!
  @IBOutlet var textView: UITextView!

  var host: HTTPBinHost {
    return (UIApplication.sharedApplication().delegate as! AppDelegate).httpbinHost
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    if method == .GET {
      host.request(withPath: "get")?.completion { completedRequest in
        dispatch_async(dispatch_get_main_queue()) {
          self.textView.text = completedRequest.responseAsString
        }
      }.run()
    }
    if method == .POST {
      host.request(.POST, withPath: "post")?.completion { completedRequest in
        dispatch_async(dispatch_get_main_queue()) {
          self.textView.text = completedRequest.responseAsString
        }
        }.run()
    }
    if method == .PUT {
      host.request(.PUT, withPath: "put")?.completion { completedRequest in
        dispatch_async(dispatch_get_main_queue()) {
          self.textView.text = completedRequest.responseAsString
        }
        }.run()
    }
    if method == .DELETE {
      host.request(.DELETE, withPath: "delete")?.completion { completedRequest in
        dispatch_async(dispatch_get_main_queue()) {
          self.textView.text = completedRequest.responseAsString
        }
        }.run()
    }
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
}
