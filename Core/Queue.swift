//
//  Queue.swift
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