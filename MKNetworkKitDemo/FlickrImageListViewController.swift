//
//  FlickrImageListViewController.swift
//  MKNetworkKit
//
//  Created by Mugunth on 15/5/15.
//  Copyright (c) 2015 Steinlogic Consulting and Training Pte Ltd. All rights reserved.
//

import UIKit

class FlickrImageListViewController: UITableViewController {

  var detailViewController: FlickrImageDetailViewController? = nil
  var images = [FlickrImage]()

  override func awakeFromNib() {
    super.awakeFromNib()
    if UIDevice.current.userInterfaceIdiom == .pad {
      self.clearsSelectionOnViewWillAppear = false
      self.preferredContentSize = CGSize(width: 320.0, height: 600.0)
    }
  }

  var flickrHost: FlickrClient {
    return (UIApplication.shared.delegate as! AppDelegate).flickrHost
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    if let split = self.splitViewController {
      let controllers = split.viewControllers
      let navigationController = controllers[controllers.count-1] as! UINavigationController
      self.detailViewController = navigationController.topViewController as? FlickrImageDetailViewController

      flickrHost.fetchImages("Singapore") {images -> Void in
        self.images = images
        DispatchQueue.main.async { () -> Void in
          self.tableView.reloadData()
        }
      }
    }
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  // MARK: - Segues

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "showDetail" {
      if let indexPath = self.tableView.indexPathForSelectedRow {
        let object = images[indexPath.row]
        let controller = (segue.destination as! UINavigationController).topViewController as! FlickrImageDetailViewController
        controller.detailItem = object
        controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
        controller.navigationItem.leftItemsSupplementBackButton = true
      }
    }
  }

  // MARK: - Table View

  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return images.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "FlickrImageCell", for: indexPath) as! FlickrImageCell
    let flickrImage = images[indexPath.row]
    cell.bind(flickrImage)
    return cell
  }
}

