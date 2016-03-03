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
import ImageIO
#if os(watchOS)
  import WatchKit
#endif

// MARK: Extension methods on String to load a remote image
public extension String {
  static let imageHost = Host(cacheDirectory: "MKNetworkKit")
  public func loadRemoteImage(decompress: Bool = true, handler:(UIImage?, Bool) -> Void) -> Request {
    return String.imageHost.request(withUrlString:self)
      .completion { (request) -> Void in
        let cachedResponse = [.ResponseAvailableFromCache, .StaleResponseAvailableFromCache].contains(request.state)
        if decompress {
          handler(request.responseAsDecompressedImage, cachedResponse)
        } else {
          handler(request.responseAsImage, cachedResponse)
        }
      }.run()
  }
}

extension Request {
  public var responseAsImage: UIImage? {
    var token: dispatch_once_t = 0
    var scale: CGFloat = 2.0
    dispatch_once(&token) {
      #if os(watchOS)
        scale = WKInterfaceDevice.currentDevice().screenScale
      #endif
      #if os(iOS)
        scale = UIScreen.mainScreen().scale
      #endif
    }

    return UIImage(data:responseData, scale: scale)
  }

  public var responseAsDecompressedImage: UIImage? {
    guard let source = CGImageSourceCreateWithData(responseData as CFDataRef, nil) else { return nil }
    guard let cgImage = CGImageSourceCreateImageAtIndex(source, 0,
      [(kCGImageSourceShouldCache as String): false]) else { return nil }

    var token: dispatch_once_t = 0
    var scale: CGFloat = 2.0
    dispatch_once(&token) {
      #if os(watchOS)
        scale = WKInterfaceDevice.currentDevice().screenScale
      #endif
      #if os(iOS)
        scale = UIScreen.mainScreen().scale
      #endif
    }

    return UIImage(CGImage: cgImage, scale: scale, orientation: .Up)
  }

  #if APPEX
  public static var automaticNetworkActivityIndicator: Bool = false {
    didSet {
      if automaticNetworkActivityIndicator {
        Request.runningRequestsUpdatedHandler = { count in
          dispatch_async(dispatch_get_main_queue()) {
            #if os(iOS)
              UIApplication.sharedApplication().networkActivityIndicatorVisible = count > 0
            #endif
          }
        }
      }
    }
  }
  #endif
}
