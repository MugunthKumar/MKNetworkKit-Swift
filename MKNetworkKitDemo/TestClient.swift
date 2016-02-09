//
//  TestClient.swift
//  MKNetworkKitDemo
//
//  Created by Mugunth Kumar on Feb 9 2016.
//  Copyright © 2016 Steinlogic Consulting and Training Pte Ltd. All rights reserved.
//

import UIKit
import MKNetworkKit

class TestClient: Host {
    init() {
        super.init(name: "mknetworkkit.mk.sg")
        self.secure = false
    }

  func uploadImage (imageFilePath: String, completionHandler: (Void -> Void)) {

    guard let request = request(.POST, withPath: "upload.php", parameters: ["Submit": "1"]) else { return }
    if let imageEntity = MultipartEntity(mimetype: "application/jpeg", filePath: imageFilePath) {
      request.appendMultipartEntity("image", value: imageEntity)
    }
    request.completion{ completedRequest -> Void in
      print (completedRequest.responseAsString!)
    }.run()
  }
}
