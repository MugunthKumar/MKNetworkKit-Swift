//
//  FlickrImageCell.swift
//  iCashSG 2
//
//  Created by Mugunth Kumar on 11/6/15.
//  Copyright (c) 2015 Steinlogic Consulting and Training Pte Ltd. All rights reserved.
//

import UIKit
import MKNetworkKit

class FlickrImageCell: UITableViewCell {

  @IBOutlet weak var photoView : UIImageView!
  var imageFetchRequest : Request? = nil

  override func prepareForReuse() {
    super.prepareForReuse()
    photoView.image = nil;
    imageFetchRequest?.state = .Cancelled;
  }

  func bind(flickrImage : FlickrImage) {

    flickrImage.thumbnailImageUrlString?.loadRemoteImage({ image -> Void in
      self.photoView.image = image
    })

    let client = (UIApplication.sharedApplication().delegate as! AppDelegate).host
    imageFetchRequest = client?.fetchImage(flickrImage.thumbnailImageUrlString!) { (image : UIImage?) -> Void in
      dispatch_async(dispatch_get_main_queue()) { () -> Void in
        UIView.transitionWithView(self.superview!, duration: 0.5, options: .TransitionCrossDissolve, animations: {
          () -> Void in
          self.photoView.image = image;
          }, completion: nil)
      }
    }
  }
}
