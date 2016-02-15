//
//  NSHTTPURLResponse.swift
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
//

import Foundation

public extension NSHTTPURLResponse {

  public func headerValue(key: String) -> String? {
    let lowercaseKey = String(key).lowercaseString
    for (k, v) in allHeaderFields {
      if String(k).lowercaseString == lowercaseKey {
        return v as? String
      }
    }
    return nil
  }

  public var isContentTypeImage: Bool {
    if let _ = headerValue("Content-Type")?.lowercaseString.rangeOfString("image") {
      return true
    } else {
      return false
    }
  }

  public var cacheExpiryDate: NSDate? {
    if let expiresOn = headerValue("Expires") {
      if let expiresOnDate = NSDate.dateFromRFC1123DateString(expiresOn) {
        return expiresOnDate
      }
    }

    if let cacheControl = headerValue("Cache-Control") {
      let entities = cacheControl.componentsSeparatedByString(",")
      for entity in entities {
        if let _ = entity.rangeOfString("no-cache") {
          return nil
        }
        if let _ = entity.rangeOfString("max-age") {
          let maxAgeComponents = entity.componentsSeparatedByString("=")
          if let maxAge = Double(maxAgeComponents[1]) {
            return NSDate().dateByAddingTimeInterval(maxAge)
          }
        }
      }
    }

    return nil
  }
}