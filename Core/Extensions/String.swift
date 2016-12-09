//
//  String.swift
//  MKNetworkKitDemo
//
//  Created by Mugunth Kumar on Jul 15 2016.
//  Copyright © 2016 Steinlogic Consulting and Training Pte Ltd. All rights reserved.
//

import Foundation
public extension String {
  public var filePathSafeString: String {
    let characterSet = CharacterSet(charactersIn: "/*?!:").inverted
    return addingPercentEncoding(withAllowedCharacters: characterSet) ?? ""
  }
}
