//
//  AuthTestViewController.swift
//  MKNetworkKitDemo
//
//  Created by Mugunth Kumar on Feb 9 2016.
//  Copyright © 2016 Steinlogic Consulting and Training Pte Ltd. All rights reserved.
//

import UIKit

class AuthTestViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    host.performQueueTest()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  var host: HTTPBinHost {
    return (UIApplication.sharedApplication().delegate as! AppDelegate).httpbinHost
  }

  @IBAction func basicAuthAction(sender: AnyObject) {
    host.performBasicAuthentication {}
  }

  @IBAction func hiddenBasicAuthAction(sender: AnyObject) {
    host.performHiddenBasicAuthentication {}
  }

  @IBAction func digestAuthAction(sender: AnyObject) {
    host.performDigestAuthentication {}
  }

}
