//
//  QueueOperation.swift
//  MKNetworkKitDemo
//
//  Created by Mugunth Kumar on Feb 10 2016.
//  Copyright © 2016 Steinlogic Consulting and Training Pte Ltd. All rights reserved.
//

import UIKit

public class QueueOperation: NSOperation {
  var request: Request
  public init(request: Request) {
    self.request = request
    super.init()
  }

  public override func start() {
    request.stateWillChange = { updatedRequest in
      if ![.Started, .Error, .Completed, .Cancelled].contains(updatedRequest.state) {
        self.willChangeValueForKey("isReady")
        self.willChangeValueForKey("isExecuting")
      } else {
        self.willChangeValueForKey("isFinished")
      }
      if updatedRequest.state == .Ready {
        self.willChangeValueForKey("isReady")
      }
      if updatedRequest.state == .Cancelled {
        self.willChangeValueForKey("isCancelled")
      }
    }

    request.stateDidChange = { updatedRequest in
      if ![.Started, .Error, .Completed, .Cancelled].contains(updatedRequest.state) {
        self.didChangeValueForKey("isReady")
        self.didChangeValueForKey("isExecuting")
      } else {
        self.didChangeValueForKey("isFinished")
      }
      if updatedRequest.state == .Ready {
        self.didChangeValueForKey("isReady")
      }
      if updatedRequest.state == .Cancelled {
        self.didChangeValueForKey("isCancelled")
      }
    }

    if !cancelled {
      //print ("started \(request.request?.URL?.absoluteString)")
      request.run()
    }
  }

  public override var asynchronous: Bool {
    return true
  }

  public override var ready: Bool {
    return request.state == .Ready
  }

  public override var executing: Bool {
    return ![.Error, .Completed, .Cancelled].contains(request.state)
  }

  public override var finished: Bool {
    return [.Error, .Completed, .Cancelled].contains(request.state)
  }

  public override func cancel() {
    request.cancel()
    super.cancel()
  }
}
