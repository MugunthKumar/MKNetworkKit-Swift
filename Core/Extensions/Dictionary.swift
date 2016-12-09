//
//  Dictionary.swift
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

public extension Dictionary {
  public var URLEncodedString: String {
    var encodedString = self.reduce("") {
      let (key, value) = $1
      return "\($0)" + "\(key)=\(value)&"
    }
    if encodedString.characters.count > 0 {
      encodedString.remove(at: encodedString.characters.index(before: encodedString.endIndex))
    }

    let filterSet = (CharacterSet.urlFragmentAllowed as NSCharacterSet).mutableCopy() as! NSMutableCharacterSet
    filterSet.formUnion(with: .urlPathAllowed)
    filterSet.formUnion(with: .urlQueryAllowed)
    filterSet.formUnion(with: .urlHostAllowed)

    return encodedString.addingPercentEncoding(withAllowedCharacters: filterSet as CharacterSet) ?? ""
  }

  public var JSONString: String? {
    var data: Data?
    do {
      try data = JSONSerialization.data(withJSONObject: self as AnyObject, options:[])
    } catch let error as NSError {
      Log.warn(error)
    }

    guard data != nil else {
      return nil
    }
    return NSString(data: data!, encoding: String.Encoding.utf8.rawValue) as String?
  }
}
