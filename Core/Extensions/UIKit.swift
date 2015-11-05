//
//  UIKitExtensions.swift
//  MKNetworkKit
//
//  Created by Mugunth Kumar
//  Copyright © 2015 - 2020 Steinlogic Consulting and Training Pte Ltd. All rights reserved.
//
//  MIT LICENSE (REQUIRES ATTRIBUTION)
//	ATTRIBUTION FREE LICENSING AVAILBLE (for a license fee)
//  Email mugunth.kumar@gmail.com for details
//
//  Created by Mugunth Kumar (@mugunthkumar)
//  Copyright (C) 2015-2025 by Steinlogic Consulting And Training Pte Ltd.

//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation
import UIKit


// MARK: Extension methods on String to load a remote image
extension String {
  static let imageHost = Host(cacheDirectory: "MKNetworkKit")
  public func loadRemoteImage(handler:(UIImage?) -> Void) -> Request {
    return String.imageHost.request(withUrlString:self)
      .completion { (request) -> Void in
        dispatch_async(dispatch_get_main_queue()) {
          handler(request.responseAsImage)
        }
      }.run()
  }
}

extension Request {
  public var responseAsImage : UIImage? {
    if let data = responseData {
      return UIImage(data:data, scale: UIScreen.mainScreen().scale)
    } else {
      return nil
    }
  }

  public static var automaticNetworkActivityIndicator : Bool = false {
    didSet {
      if automaticNetworkActivityIndicator {
        Request.runningRequestsUpdatedHandler = { count in
          dispatch_async(dispatch_get_main_queue()) {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = count > 0
          }
        }
      }
    }
  }
}
