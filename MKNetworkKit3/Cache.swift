//
//  Cache.swift
//  MKNetworkKitDemo
//
//  Created by Mugunth Kumar on 15/6/15.
//  Copyright © 2015 Steinlogic Consulting and Training Pte Ltd. All rights reserved.
//

import Foundation

class Cache {

  var directory : String;

  var inMemoryCache : [String:AnyObject] = [String:AnyObject]()
  var recentKeys : [String] = [String]()

  init(directoryName : String = "AppCache", cost: Int = 25) {

    let cachesDirectory = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)[0]
    directory = cachesDirectory + "/" + directoryName

    if !(NSFileManager.defaultManager().fileExistsAtPath(directory)) {

      do {
       try NSFileManager.defaultManager().createDirectoryAtPath(directory, withIntermediateDirectories: true, attributes: nil)
      } catch let error as NSError {

        Log.error(error)
      }
    }
  }
}