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
  case crudSection = 0
  case authenticationSection = 1
  case udSection = 2
  case flickrSection = 3
  case queueSection = 4
  case numberOfSections = 5
}

class DemoListViewController: UITableViewController {

  var host: HTTPBinHost {
    return (UIApplication.shared.delegate as! AppDelegate).httpbinHost
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    if indexPath.section == TableView.authenticationSection.rawValue {
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

    if indexPath.section == TableView.queueSection.rawValue {
      host.performQueuedRequests()
    }
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "showGET" {
      let controller = segue.destination as! CRUDViewController
      controller.method = .GET
    }
    if segue.identifier == "showPOST" {
      let controller = segue.destination as! CRUDViewController
      controller.method = .POST
    }
    if segue.identifier == "showPUT" {
      let controller = segue.destination as! CRUDViewController
      controller.method = .PUT
    }
    if segue.identifier == "showDELETE" {
      let controller = segue.destination as! CRUDViewController
      controller.method = .DELETE
    }
  }
}
