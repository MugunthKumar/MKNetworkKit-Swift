//
//  UIAlertController.swift
//  MKNetworkKitDemo
//
//  Created by Mugunth Kumar on 4/11/15.
//  Copyright © 2015 Steinlogic Consulting and Training Pte Ltd. All rights reserved.
//

import Foundation
import UIKit

extension UIAlertController {
  public func show(error: NSError) {
    let alertController = UIAlertController(title: error.localizedFailureReason ?? error.localizedDescription,
      message: error.localizedRecoverySuggestion,
      preferredStyle: .Alert)
    UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
  }
}
