//
//  FlickrImage.swift
//  iCashSG 2
//
//  Created by Mugunth Kumar on 11/6/15.
//  Copyright (c) 2015 Steinlogic Consulting and Training Pte Ltd. All rights reserved.
//

import Foundation

struct FlickrImage {

  var backingStore : [String: AnyObject]
  init(jsonDictionary : [String: AnyObject]) {
    backingStore = jsonDictionary
  }

  var title : String? {
    get {
      return backingStore["title"] as? String
    }
  }

  var author : String? {
      return backingStore["name"] as? String
  }

  var farm : Int {
      return backingStore["farm"] as! Int
  }

  var server : String {
      return backingStore["server"] as! String
  }

  var id : String {
      return backingStore["id"] as! String
  }

  var secret : String {
      return backingStore["secret"] as! String
  }
  
  var thumbnailImageUrlString : String? {
      return ("https://farm\(farm).static.flickr.com/\(server)/\(id)_\(secret)_m.jpg")
  }

  var fullscreenImageUrlString : String? {
      return ("https://farm\(farm).static.flickr.com/\(server)/\(id)_\(secret)_b.jpg")
  }
}