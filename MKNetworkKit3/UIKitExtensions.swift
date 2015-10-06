//
//  UIKitExtensions.swift
//  MKNetworkKitDemo
//
//  Created by Mugunth Kumar on 15/6/15.
//  Copyright © 2015 Steinlogic Consulting and Training Pte Ltd. All rights reserved.
//

import Foundation
import UIKit

extension Request {

  public var responseAsImage : UIImage? {

    if responseData != nil {
      return UIImage(data:responseData!)
    } else {
      return nil
    }
  }
}