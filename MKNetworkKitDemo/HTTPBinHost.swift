//
//  HTTPBinHost.swift
//  MKNetworkKitDemo
//
//  Created by Mugunth Kumar on Feb 9 2016.
//  Copyright © 2016 Steinlogic Consulting and Training Pte Ltd. All rights reserved.
//

import UIKit
import MKNetworkKit

class HTTPBinHost: Host {
  init() {
    super.init(name: "httpbin.org")
    secure = true
    defaultParameterEncoding = .JSON
  }

  func testPost (_ completionHandler: ((Void) -> Void)) {
    guard let request = request(.POST, withPath: "post") else { return }
    request.appendParameter("name", value: "Mugunth")
    request.completion { completedRequest -> Void in
      print ("\(completedRequest.responseAsJSON)")
    }.run()
  }

  func performHiddenBasicAuthentication (_ completionHandler: ((Void) -> Void)) {
    guard let request = request(withPath: "hidden-basic-auth/user/passwd") else { return }
    request.appendBasicAuthorizationHeader(username: "user", password: "passwd")
    request.completion { completedRequest -> Void in
      print ("\(completedRequest.responseAsJSON)")
      }.run()
  }

  func performBasicAuthentication (_ completionHandler: ((Void) -> Void)) {
    guard let request = request(withPath: "basic-auth/user/passwd") else { return }
    request.username = "user"
    request.password = "passwd"
    request.realm = "Fake Realm"

    request.completion { completedRequest -> Void in
      print ("\(completedRequest.responseAsJSON)")
      }.run()
  }

  func performDigestAuthentication (_ completionHandler: ((Void) -> Void)) {
    guard let request = request(withPath: "digest-auth/auth/user/passwd") else { return }
    request.username = "user"
    request.password = "passwd"
    request.realm = "me@kennethreitz.com"
    request.authenticationMethod = .httpDigest
    request.completion { completedRequest -> Void in
      print ("\(completedRequest.responseAsJSON)")
      }.run()
  }

  func performQueuedRequests() {
    guard let request10 = request(withPath: "stream/10") else { return }
    guard let request20 = request(withPath: "stream/20") else { return }
    guard let request30 = request(withPath: "streadm/30") else { return } // error request
    guard let request40 = request(withPath: "stream/40") else { return }
    guard let request50 = request(withPath: "stream/50") else { return }

    let queue = Queue()
    queue.requests = [request10, request20, request30, request40, request50]
    queue.run(abortOnFirstFail: true) { completedQueue in
      if completedQueue.failedRequests.count > 0 {
        print("Failed \(completedQueue.failedRequests.map {$0.asCurlCommand})")
      } else {
        print("All completed")
      }
    }
  }
  
  func uploadImage (_ imageFilePath: String, completionHandler: ((Void) -> Void)) {
    guard let request = request(.POST, withPath: "post") else { return }
    if let imageEntity = MultipartEntity(mimetype: "application/jpeg", filePath: imageFilePath) {
      request.appendMultipartEntity("image", value: imageEntity)
    }
    request.completion{ completedRequest -> Void in
      let jsonDictionary = request.responseAsJSON as! [String:AnyObject]
//      var dataString = jsonDictionary["data"] as! String
//      dataString = dataString.stringByReplacingOccurrencesOfString("data:application/octet-stream;base64,", withString: "")
//      let data = NSData(base64EncodedString: dataString, options: .IgnoreUnknownCharacters)
//      let image = UIImage(data: data!)
      print(jsonDictionary)
      }.run()
  }
}
