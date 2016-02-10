//
//  Queue.swift
//  MKNetworkKitDemo
//
//  Created by Mugunth Kumar on Feb 10 2016.
//  Copyright © 2016 Steinlogic Consulting and Training Pte Ltd. All rights reserved.
//

import Foundation

public class Queue {
  public var requests = [Request]()
  public var failedRequests = [Request]()
  var serialQueue = dispatch_queue_create("queue", DISPATCH_QUEUE_SERIAL)
  public init() {}

  public func run(serial serialMode: Bool = true, abortOnFirstFail: Bool = false, completionHandler: (Queue -> Void)) {
    let queue = NSOperationQueue()
    if serialMode {
      queue.maxConcurrentOperationCount = 1
    }
    for request in requests {
      request.completion { (completedRequest) -> Void in
        // print("Completed \(completedRequest.request?.URL?.absoluteString)")
        if completedRequest.error != nil {
          self.failedRequests.append(completedRequest)
          if abortOnFirstFail {
            queue.cancelAllOperations()
          }
        }
      }
      dispatch_async(serialQueue) {
        queue.addOperation(QueueOperation(request: request))
      }
    }
    dispatch_async(serialQueue) {
      queue.waitUntilAllOperationsAreFinished()
      dispatch_async(dispatch_get_main_queue()) {
        completionHandler(self)
      }
    }
  }
}