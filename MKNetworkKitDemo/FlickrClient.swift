//
//  FlickrClient.swift
//  iCashSG 2
//
//  Created by Mugunth Kumar on 11/6/15.
//  Copyright (c) 2015 Steinlogic Consulting and Training Pte Ltd. All rights reserved.
//

import Foundation

#if os(iOS) || os(watchOS) || os(tvOS)
  import MKNetworkKit
  import UIKit
#endif

#if os(OSX)
  import MKNetworkKitOSX
#endif

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
        "tags": tag.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!,
        "per_page": "200",
        "format": "json",
        "nojsoncallback": "1",
        "page": String(page)
      ])
  }

  override func customizeRequest(request: Request) -> Request {
    request.appendParameter("api_key", value: flickrAPIKey)
    return request
  }

  func fetchImages (tag : String, completionHandler: (Array<FlickrImage>) -> Void) {
    guard let request = imageFetchRequest(tag, page: 0) else { return }

    request.completion {(request: Request) in
      if ([.Completed, .StaleResponseAvailableFromCache, .ResponseAvailableFromCache].contains(request.state)) {
        let jsonDictionary = request.responseAsJSON as! [String:AnyObject]
        let photosDictionary = jsonDictionary["photos"] as! [String: AnyObject]
        let flickrArray = photosDictionary["photo"] as! [[String: AnyObject]]
        completionHandler(flickrArray.map {FlickrImage(jsonDictionary: $0)})
      } else {
        print(request.error)
      }
      }.run()
  }

  #if os(iOS) || os(watchOS) || os(tvOS)
  func fetchImage (imageURLString : String, completionHandler: (UIImage?) -> Void) -> Request {
    let request = super.request(withUrlString: imageURLString)
    return request.completion {(request: Request) in
      completionHandler(request.responseAsImage)
      }.run()
  }
  #endif
  
}