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
    return (UIApplication.shared.delegate as! AppDelegate).httpbinHost
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    if method == .GET {
      host.request(withPath: "get")?.completion { completedRequest in
        DispatchQueue.main.async {
          self.textView.text = completedRequest.responseAsString
        }
      }.run()
    }
    if method == .POST {
      host.request(.POST, withPath: "post", parameters: ["A": "a", "B": "b"])?.completion { completedRequest in
        DispatchQueue.main.async {
          self.textView.text = completedRequest.responseAsString
        }
        }.run()
    }
    if method == .PUT {
      host.request(.PUT, withPath: "put")?.completion { completedRequest in
        DispatchQueue.main.async {
          self.textView.text = completedRequest.responseAsString
        }
        }.run()
    }
    if method == .DELETE {
      host.request(.DELETE, withPath: "delete")?.completion { completedRequest in
        DispatchQueue.main.async {
          self.textView.text = completedRequest.responseAsString
        }
        }.run()
    }
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
}
