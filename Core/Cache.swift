//
//  Cache.swift
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
#if os(iOS) || os(watchOS) || os(tvOS)
import UIKit
#endif

#if os(OSX)
import AppKit
#endif

public class Cache<T>: CustomDebugStringConvertible {

  //MARK:- Properties
  var fileExtension: String
  var directory: String
  var cacheCost: Int

  //MARK:- Cache Storage
  var inMemoryCache = [String:T]()
  var recentKeys = [String]()

  //MARK:- Queue
  var queue: dispatch_queue_t = dispatch_queue_create("com.mknetworkkit.cachequeue", DISPATCH_QUEUE_SERIAL)
  var diskQueue: dispatch_queue_t = dispatch_queue_create("com.mknetworkkit.diskqueue", DISPATCH_QUEUE_SERIAL)

  public var debugDescription: String {
    return directory
  }

  // MARK:- Designated Initializer
  public init(cost: Int = 50, directoryName: String = "AppCache", fileExtension: String = "cachearchive") {
    let cachesDirectory = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true).first!
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

    #if os(iOS) || os(tvOS)
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

  // MARK:- Disk cache
  func makePath(key: String) -> String {
    let string = "\(self.directory)/\(key.filePathSafeString).\(fileExtension)"
    return string
  }

  func fetchFromDisk (key: String) -> T? {
    let filePath = makePath(key)
    return NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? T
  }
  
  func cacheToDisk (key: String, _ value: T) {
    let filePath = makePath(key)
    if NSFileManager.defaultManager().fileExistsAtPath(filePath) {
       try! NSFileManager.defaultManager().removeItemAtPath(filePath)
    }

    let data = NSKeyedArchiver.archivedDataWithRootObject(value as! AnyObject)
    dispatch_async(diskQueue) {
      let written = data.writeToFile(filePath, atomically: true)
      if !written {
        print ("Failed \(filePath)")
      }
    }
  }

  //MARK:- Caching methods
  subscript(key: String) -> T? {
    get {
      if let valueToBeReturned = inMemoryCache[key] {
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

  // MARK:- Cleanup related methods
  func enforceMemoryCost() {
    if recentKeys.count <= cacheCost { return }
    dispatch_async(self.queue) {
      let lruKey = self.recentKeys.removeLast()
      let lruValue = self.inMemoryCache[lruKey]
      if let valueToCache = lruValue {
        self.cacheToDisk(lruKey, valueToCache)
        self.inMemoryCache.removeValueForKey(lruKey)
      }
    }
  }

  func flushToDisk() {
    dispatch_async(self.queue) {
      for (key, value) in self.inMemoryCache {
        self.cacheToDisk(key, value)
      }
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
      try NSFileManager.defaultManager().createDirectoryAtPath(directory, withIntermediateDirectories: true, attributes: nil)
    } catch let error as NSError {
      Log.warn(error)
    }
  }

  // MARK:- De-initalizer
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