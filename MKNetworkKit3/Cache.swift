//
//  Cache.swift
//  MKNetworkKitDemo
//
//  Created by Mugunth Kumar on 15/6/15.
//  Copyright © 2015 Steinlogic Consulting and Training Pte Ltd. All rights reserved.
//

import Foundation
import UIKit

class Cache {

  var fileExtension : String
  var directory : String

  var inMemoryCache : [String:AnyObject] = [String:AnyObject]()
  var recentKeys : [String] = [String]()
  var cacheCost : Int = 10
  var queue : dispatch_queue_t = dispatch_queue_create("com.mknetworkkit.cachequeue", DISPATCH_QUEUE_SERIAL)
  var diskQueue : dispatch_queue_t = dispatch_queue_create("com.mknetworkkit.diskqueue", DISPATCH_QUEUE_SERIAL)

  // MARK: Initializer
  init(cost: Int = 10, directoryName : String = "AppCache", fileExtension : String = "mkcache") {

    let cachesDirectory = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)[0]
    directory = cachesDirectory + "/" + directoryName
    cacheCost = cost
    self.fileExtension = fileExtension

    if !(NSFileManager.defaultManager().fileExistsAtPath(directory)) {

      do {
        try NSFileManager.defaultManager().createDirectoryAtPath(directory, withIntermediateDirectories: true, attributes: nil)
      } catch let error as NSError {

        Log.error(error)
      }
    }

    #if os(iOS) || os(watchOS)

      NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidReceiveMemoryWarningNotification,
        object: nil, queue: nil, usingBlock: { (_) in
          self.flushToDisk()
      })
      NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidEnterBackgroundNotification,
        object: nil, queue: nil, usingBlock: { (_) in
          self.flushToDisk()
      })
      NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationWillResignActiveNotification,
        object: nil, queue: nil, usingBlock: { (_) in
          self.flushToDisk()
      })
      NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationWillTerminateNotification,
        object: nil, queue: nil, usingBlock: { (_) in
          self.flushToDisk()
      })

    #endif

    #if os(OSX)

      NSNotificationCenter.defaultCenter().addObserverForName(NSApplicationWillHideNotification,
      object: nil, queue: nil, usingBlock: { (_) in
      self.flushToDisk()
      })
      NSNotificationCenter.defaultCenter().addObserverForName(NSApplicationWillResignActiveNotification,
      object: nil, queue: nil, usingBlock: { (_) in
      self.flushToDisk()
      })
      NSNotificationCenter.defaultCenter().addObserverForName(NSApplicationWillTerminateNotification,
      object: nil, queue: nil, usingBlock: { (_) in
      self.flushToDisk()
      })

    #endif
  }

  // MARK: Disk cache related methods

  func makePath(key : String) -> String {

    return "\(self.directory)/\(key).\(fileExtension)"
  }

  func fetchFromDisk (key : String) -> AnyObject? {

    let filePath = makePath(key)
    return NSKeyedUnarchiver.unarchiveObjectWithFile(filePath)
  }
  
  func cacheToDisk (key : String, _ value : AnyObject) {

    let filePath = makePath(key)

    if NSFileManager.defaultManager().fileExistsAtPath(filePath) {
      do {
        try NSFileManager.defaultManager().removeItemAtPath(filePath)
      }
      catch {
        // this try never fails because we check for file existence prior hand
        Log.info("Missing file")
      }
    }

    let data = NSKeyedArchiver.archivedDataWithRootObject(value)
    dispatch_async(diskQueue) {
      data.writeToFile(filePath, atomically: true)
    }
  }

  //MARK: Caching methods
  subscript(key: String) -> AnyObject? {
    get {
      if let valueToBeReturned = self.inMemoryCache[key] {
        return valueToBeReturned
      }
      if let valueToBeReturned = fetchFromDisk(key) {
        self[key] = valueToBeReturned // bring this value back into memory
        return valueToBeReturned
      }
      return nil
    }
    set {
      dispatch_async(self.queue) {
        self.inMemoryCache[key] = newValue
        self.recentKeys.append(key)
        self.enforceMemoryCost()
      }
    }
  }

  func enforceMemoryCost() {

    if self.recentKeys.count > self.cacheCost {

      var lruKey : String?
      var lruValue : String?

      dispatch_async(self.queue) {
        lruKey = self.recentKeys.removeLast()
        lruValue = self.recentKeys.removeLast()
      }

      if let valueToCache = lruValue {
        cacheToDisk(lruKey!, valueToCache)
        enforceDiskCost()
      }
    }
  }

  func enforceDiskCost() {
    
  }


  // MARK: Cleanup related methods
  func flushToDisk() {

    for (key, value) in inMemoryCache {
      cacheToDisk(key, value)
    }

    dispatch_async(self.queue) {
      self.inMemoryCache.removeAll()
      self.recentKeys.removeAll()
    }
  }

  func emptyCache() {

    dispatch_async(self.queue) {
      self.inMemoryCache.removeAll()
      self.recentKeys.removeAll()
    }

    do {
     try NSFileManager.defaultManager().removeItemAtPath(directory)
    } catch let error as NSError {
      Log.warn(error)
    }
  }

  deinit {

    #if os(iOS)

      NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidReceiveMemoryWarningNotification, object: nil)
      NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidEnterBackgroundNotification, object: nil)
      NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillResignActiveNotification, object: nil)
      NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillTerminateNotification, object: nil)

    #endif

    #if os(OSX)

      NSNotificationCenter.defaultCenter().removeObserver(self, name: NSApplicationWillHideNotification, object: nil)
      NSNotificationCenter.defaultCenter().removeObserver(self, name: NSApplicationWillResignActiveNotification, object: nil)
      NSNotificationCenter.defaultCenter().removeObserver(self, name: NSApplicationWillTerminateNotification, object: nil)

    #endif
  }
}