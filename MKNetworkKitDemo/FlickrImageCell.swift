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
    photoView.image = nil
    imageFetchRequest?.cancel()
  }

  func bind(_ flickrImage : FlickrImage) {
    imageFetchRequest = flickrImage.thumbnailImageUrlString?.loadRemoteImage { image, cached -> Void in
      DispatchQueue.main.async { () -> Void in
        if let view = self.superview {
          UIView.transition(with: view, duration: 0.5, options: .transitionCrossDissolve, animations: {
            () -> Void in
            self.photoView.image = image
            }, completion: nil)
        }
      }
    }
  }
}
