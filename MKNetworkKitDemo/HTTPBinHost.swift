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
  }

  func testPost (completionHandler: (Void -> Void)) {
    guard let request = request(.POST, withPath: "post") else { return }
    request.appendParameter("name", value: "Mugunth")
    request.completion { completedRequest -> Void in
      print (completedRequest.responseAsJSON)
    }.run()
  }

  func performHiddenBasicAuthentication (completionHandler: (Void -> Void)) {
    guard let request = request(withPath: "hidden-basic-auth/user/passwd") else { return }
    request.appendBasicAuthorizationHeader(username: "user", password: "passwd")
    request.completion { completedRequest -> Void in
      print (completedRequest.responseAsJSON)
      print (completedRequest.error)
      }.run()
  }

  func performBasicAuthentication (completionHandler: (Void -> Void)) {
    guard let request = request(withPath: "basic-auth/user/passwd") else { return }
    request.username = "user"
    request.password = "passwd"
    request.realm = "Fake Realm"
    request.completion { completedRequest -> Void in
      print (completedRequest.responseAsJSON)
      }.run()
  }
  func uploadImage (imageFilePath: String, completionHandler: (Void -> Void)) {
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
