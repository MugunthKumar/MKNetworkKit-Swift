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

class FlickrClient: Host {

  var flickrAPIKey: String

  init(apiKey : String) {
    flickrAPIKey = apiKey
    super.init(name: "api.flickr.com", path:"services/rest")
    self.secure = true
  }

  @discardableResult
  internal func imageFetchRequest(_ tag : String, page: Int) -> Request? {
    return super.request(withPath: "", parameters:
      ["method": "flickr.photos.search",
       "tags": tag.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!,
        "per_page": "200",
        "format": "json",
        "nojsoncallback": "1",
        "page": String(page)
      ])
  }

  @discardableResult
  override func customizeRequest(_ request: Request) -> Request {
    request.appendParameter("api_key", value: flickrAPIKey)
    return request
  }

  func fetchImages (_ tag : String, completionHandler: @escaping ([FlickrImage]) -> Void) {
    guard let request = imageFetchRequest(tag, page: 0) else { return }

    request.completion {request in
      if ([.Completed, .StaleResponseAvailableFromCache, .ResponseAvailableFromCache].contains(request.state)) {
        let jsonDictionary = request.responseAsJSON as! [String:AnyObject]
        let photosDictionary = jsonDictionary["photos"] as! [String: AnyObject]
        let flickrArray = photosDictionary["photo"] as! [[String: AnyObject]]
        completionHandler(flickrArray.map {FlickrImage(jsonDictionary: $0)})
      } else {
        print("\(String(describing: request.error))")
      }
      }.run()
  }

  #if os(iOS) || os(watchOS) || os(tvOS)
  @discardableResult
  func fetchImage (_ imageURLString : String, completionHandler: @escaping (UIImage?) -> Void) -> Request? {
    let request = super.request(withAbsoluteURLString: imageURLString)
    return request?.completion {request in
      completionHandler(request.responseAsImage())
      }.run()
  }
  #endif
  
}
