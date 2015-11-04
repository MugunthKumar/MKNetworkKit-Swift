//
//  FlickrClient.swift
//  iCashSG 2
//
//  Created by Mugunth Kumar on 11/6/15.
//  Copyright (c) 2015 Steinlogic Consulting and Training Pte Ltd. All rights reserved.
//

import Foundation
import UIKit
import MKNetworkKit

class FlickrClient : Host {

  var flickrAPIKey : String;

  init(apiKey : String) {

    flickrAPIKey = apiKey;
    super.init(name: "api.flickr.com", path:"services/rest")
    self.secure = true
  }

  internal func imageFetchRequest(tag : String, page: Int) -> Request? {
    return super.request(withPath: "", parameters:
      ["method": "flickr.photos.search",
      "api_key": flickrAPIKey,
      "tags": tag.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!,
        "per_page": "200",
        "format": "json",
        "nojsoncallback": "1",
        "page": String(page)
      ])
  }

  func fetchImages (tag : String, completionHandler: (Array<FlickrImage>) -> Void) {
    guard let request = imageFetchRequest(tag, page: 0) else { return }
    
    request.completion {(request: Request) in
      let jsonDictionary = request.responseAsJSON as! [String:AnyObject]
      let photosDictionary = jsonDictionary["photos"] as! [String: AnyObject]
      let flickrArray = photosDictionary["photo"] as! [[String: AnyObject]]
      completionHandler(flickrArray.map {FlickrImage(jsonDictionary: $0)})
    }.run()
  }

  func fetchImage (imageURLString : String, completionHandler: (UIImage?) -> Void) -> Request {
    let request = super.request(withUrlString: imageURLString)
    return request.completion {(request: Request) in
      completionHandler(request.responseAsImage)
    }.run()
  }
  
}