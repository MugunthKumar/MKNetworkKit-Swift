//
//  FlickrClient.swift
//  iCashSG 2
//
//  Created by Mugunth Kumar on 11/6/15.
//  Copyright (c) 2015 Steinlogic Consulting and Training Pte Ltd. All rights reserved.
//

import Foundation
import UIKit

class FlickrClient : Host {

  var flickrAPIKey : String;

  init(apiKey : String) {

    flickrAPIKey = apiKey;
    super.init(name: "api.flickr.com", path:"services/rest/?method=")
    self.secure = true
  }

  internal func imageFetchRequest(tag : String, page: Int) -> Request? {

    return super.createRequestWithPath("flickr.photos.search&api_key=\(flickrAPIKey)&tags=\(tag.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!)&per_page=200&format=json&nojsoncallback=1&page=\(page)")
  }

  func fetchImages (tag : String, completionHandler: (Array<FlickrImage>) -> Void) {

    guard let request = imageFetchRequest(tag, page: 0) else { return }

    request.completionHandlers.append {(request: Request) in

      let jsonDictionary = request.responseAsJSON as! [String:AnyObject]
      let photosDictionary = jsonDictionary["photos"] as! [String: AnyObject]
      let flickrArray = photosDictionary["photo"] as! [[String: AnyObject]]
      completionHandler(flickrArray.map {FlickrImage(jsonDictionary: $0)})
    }

    self.startRequest(request)
  }

  func fetchImage (imageURLString : String, completionHandler: (UIImage?) -> Void) -> Request {

    let request = super.createRequestWithURLString(imageURLString)

    request.completionHandlers.append {(request: Request) in

      completionHandler(request.responseAsImage)
    }

    self.startRequest(request)
    return request
  }
  
}