//
//  DemoListViewController.swift
//  MKNetworkKitDemo
//
//  Created by Mugunth Kumar on Feb 12 2016.
//  Copyright © 2016 Steinlogic Consulting and Training Pte Ltd. All rights reserved.
//

import Foundation
import UIKit

private enum TableView: Int {
  case CRUDSection = 0
  case AuthenticationSection = 1
  case UDSection = 2
  case FlickrSection = 3
  case QueueSection = 4
  case NumberOfSections = 5
}

class DemoListViewController: UITableViewController {

  var host: HTTPBinHost {
    return (UIApplication.sharedApplication().delegate as! AppDelegate).httpbinHost
  }

  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    tableView.deselectRowAtIndexPath(indexPath, animated: true)
    if indexPath.section == TableView.AuthenticationSection.rawValue {
      if indexPath.row == 0 {
        host.performBasicAuthentication {}
      }
      if indexPath.row == 1 {
        host.performHiddenBasicAuthentication {}
      }
      if indexPath.row == 2 {
        host.performDigestAuthentication {}
      }
    }

    if indexPath.section == TableView.QueueSection.rawValue {
      host.performQueuedRequests()
    }
  }

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "showGET" {
      let controller = segue.destinationViewController as! CRUDViewController
      controller.method = .GET
    }
    if segue.identifier == "showPOST" {
      let controller = segue.destinationViewController as! CRUDViewController
      controller.method = .POST
    }
    if segue.identifier == "showPUT" {
      let controller = segue.destinationViewController as! CRUDViewController
      controller.method = .PUT
    }
    if segue.identifier == "showDELETE" {
      let controller = segue.destinationViewController as! CRUDViewController
      controller.method = .DELETE
    }
  }
}
