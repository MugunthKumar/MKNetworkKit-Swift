//
//  NSDictionary.swift
//  MKNetworkKitDemo
//
//  Created by Mugunth Kumar on 4/11/15.
//  Copyright © 2015 Steinlogic Consulting and Training Pte Ltd. All rights reserved.
//

import Foundation

extension Dictionary {
  var URLEncodedString : String {
    var encodedString = self.reduce("?") {
      let (key, value) = $1
      return "\($0)" + "\(key)=\(value)&"
    }
    if encodedString.characters.count > 0 {
      encodedString.removeAtIndex(encodedString.endIndex.predecessor());
    }
    return encodedString;
  }

  var JSONString : String? {
    let stringizedDictionary = self.map {(key, value) in
      return ["\(key)","\(value)"]
    }
    var data : NSData?
    do {
      try data = NSJSONSerialization.dataWithJSONObject(stringizedDictionary, options:
        NSJSONWritingOptions.PrettyPrinted)
    } catch let error as NSError {
      Log.warn(error)
    }

    guard data != nil else {
      return nil
    }
    return NSString(data: data!, encoding: NSUTF8StringEncoding) as String?
  }
}