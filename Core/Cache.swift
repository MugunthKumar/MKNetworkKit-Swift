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

open class Cache<T>: CustomDebugStringConvertible {

  //MARK:- Properties
  var fileExtension: String
  var directory: String
  var cacheCost: Int

  //MARK:- Cache Storage
  var inMemoryCache = [String:T]()
  var recentKeys = [String]()

  //MARK:- Queue
  var queue: DispatchQueue = DispatchQueue(label: "com.mknetworkkit.cachequeue", attributes: [])
  var diskQueue: DispatchQueue = DispatchQueue(label: "com.mknetworkkit.diskqueue", attributes: [])

  open var debugDescription: String {
    return directory
  }

  // MARK:- Designated Initializer
  public init(cost: Int = 50, directoryName: String = "AppCache", fileExtension: String = "cachearchive") {
    let cachesDirectory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
    directory = cachesDirectory + "/" + directoryName
    cacheCost = cost
    self.fileExtension = fileExtension

    if !(FileManager.default.fileExists(atPath: directory)) {
      do {
        try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true, attributes: nil)
      } catch let error as NSError {
        Log.error(error)
      }
    }

    #if os(iOS) || os(tvOS)
      NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationDidReceiveMemoryWarning,
        object: nil, queue: nil, using: { (_) in
          self.flushToDisk()
      })
      NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationDidEnterBackground,
        object: nil, queue: nil, using: { (_) in
          self.flushToDisk()
      })
      NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationWillResignActive,
        object: nil, queue: nil, using: { (_) in
          self.flushToDisk()
      })
      NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationWillTerminate,
        object: nil, queue: nil, using: { (_) in
          self.flushToDisk()
      })
    #endif

    #if os(OSX)
      NotificationCenter.default.addObserver(forName: NSNotification.Name.NSApplicationWillHide, object: nil, queue: nil) { (_) in
        self.flushToDisk()
      }
      NotificationCenter.default.addObserver(forName: NSNotification.Name.NSApplicationWillResignActive, object: nil, queue: nil) { (_) in
        self.flushToDisk()
      }
      NotificationCenter.default.addObserver(forName: NSNotification.Name.NSApplicationWillTerminate, object: nil, queue: nil) { (_) in
        self.flushToDisk()
      }
    #endif
  }

  // MARK:- Disk cache
  func makePath(_ key: String) -> String {
    let md5Key = key.data(using: String.Encoding.utf8)!.md5
    return "\(self.directory)/\(md5Key).\(fileExtension)"
  }

  func fetchFromDisk (_ key: String) -> T? {
    let filePath = makePath(key)
    return NSKeyedUnarchiver.unarchiveObject(withFile: filePath) as? T
  }
  
  func cacheToDisk (_ key: String, _ value: T) {
    let filePath = makePath(key)
    if FileManager.default.fileExists(atPath: filePath) {
       try! FileManager.default.removeItem(atPath: filePath)
    }

    let data = NSKeyedArchiver.archivedData(withRootObject: value as AnyObject)
    diskQueue.async {
      do {
      try data.write(to: URL(fileURLWithPath: filePath), options: .atomicWrite)
      } catch let error as NSError {
        print ("Failed \(filePath) with error \(error)")
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
      self.queue.async {
        self.inMemoryCache[key] = newValue
        self.recentKeys.append(key)
        self.enforceMemoryCost()
      }
    }
  }

  // MARK:- Cleanup related methods
  func enforceMemoryCost() {
    if recentKeys.count <= cacheCost { return }
    self.queue.async {
      let lruKey = self.recentKeys.removeLast()
      let lruValue = self.inMemoryCache[lruKey]
      if let valueToCache = lruValue {
        self.cacheToDisk(lruKey, valueToCache)
        self.inMemoryCache.removeValue(forKey: lruKey)
      }
    }
  }

  func flushToDisk() {
    self.queue.async {
      for (key, value) in self.inMemoryCache {
        self.cacheToDisk(key, value)
      }
      self.inMemoryCache.removeAll()
      self.recentKeys.removeAll()
    }
  }

  func emptyCache() {
    self.queue.async {
      self.inMemoryCache.removeAll()
      self.recentKeys.removeAll()
    }
    do {
     try FileManager.default.removeItem(atPath: directory)
      try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true, attributes: nil)
    } catch let error as NSError {
      Log.warn(error)
    }
  }

  // MARK:- De-initalizer
  deinit {
    #if os(iOS)
      NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidReceiveMemoryWarning, object: nil)
      NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
      NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
      NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillTerminate, object: nil)
    #endif
    #if os(OSX)
      NotificationCenter.default.addObserver(forName: NSNotification.Name.NSApplicationWillHide, object: nil, queue: nil) { (_) in
        self.flushToDisk()
      }
      NotificationCenter.default.addObserver(forName: NSNotification.Name.NSApplicationWillResignActive, object: nil, queue: nil) { (_) in
        self.flushToDisk()
      }
      NotificationCenter.default.addObserver(forName: NSNotification.Name.NSApplicationWillTerminate, object: nil, queue: nil) { (_) in
        self.flushToDisk()
      }
    #endif
  }
}
