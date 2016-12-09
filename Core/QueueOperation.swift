//
//  QueueOperation.swift
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

import UIKit

open class QueueOperation: Operation {
  var request: Request
  public init(request: Request) {
    self.request = request
    super.init()
  }

  open override func start() {
    request.stateWillChange = { updatedRequest in
      if ![.Started, .Error, .Completed, .Cancelled].contains(updatedRequest.state) {
        self.willChangeValue(forKey: "isReady")
        self.willChangeValue(forKey: "isExecuting")
      } else {
        self.willChangeValue(forKey: "isFinished")
      }
      if updatedRequest.state == .Ready {
        self.willChangeValue(forKey: "isReady")
      }
      if updatedRequest.state == .Cancelled {
        self.willChangeValue(forKey: "isCancelled")
      }
    }

    request.stateDidChange = { updatedRequest in
      if ![.Started, .Error, .Completed, .Cancelled].contains(updatedRequest.state) {
        self.didChangeValue(forKey: "isReady")
        self.didChangeValue(forKey: "isExecuting")
      } else {
        self.didChangeValue(forKey: "isFinished")
      }
      if updatedRequest.state == .Ready {
        self.didChangeValue(forKey: "isReady")
      }
      if updatedRequest.state == .Cancelled {
        self.didChangeValue(forKey: "isCancelled")
      }
    }

    if !isCancelled {
      //print ("started \(request.request?.URL?.absoluteString)")
      request.run()
    }
  }

  open override var isAsynchronous: Bool {
    return true
  }

  open override var isReady: Bool {
    return request.state == .Ready
  }

  open override var isExecuting: Bool {
    return ![.Error, .Completed, .Cancelled].contains(request.state)
  }

  open override var isFinished: Bool {
    return [.Error, .Completed, .Cancelled].contains(request.state)
  }

  open override func cancel() {
    request.cancel()
    super.cancel()
  }
}
