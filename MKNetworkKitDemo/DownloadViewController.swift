//
//  DownloadViewController.swift
//  MKNetworkKitDemo
//
//  Created by Mugunth Kumar on Feb 12 2016.
//  Copyright © 2016 Steinlogic Consulting and Training Pte Ltd. All rights reserved.
//

import UIKit

class DownloadViewController: UIViewController {

  var flickrHost: FlickrClient {
    return (UIApplication.sharedApplication().delegate as! AppDelegate).flickrHost
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    flickrHost.fetchOriginal()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


  /*
  // MARK: - Navigation

  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
  // Get the new view controller using segue.destinationViewController.
  // Pass the selected object to the new view controller.
  }
  */

}
