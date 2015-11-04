//
//  AppDelegate.swift
//  MKNetworkKitDemo-Mac
//
//  Created by Mugunth Kumar on 4/11/15.
//  Copyright © 2015 Steinlogic Consulting and Training Pte Ltd. All rights reserved.
//

import Cocoa
import MKNetworkKitOSX

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  var host : FlickrClient!

  func applicationDidFinishLaunching(aNotification: NSNotification) {
    // Insert code here to initialize your application
    host = FlickrClient(apiKey:"210af0ac7c5dad997a19f7667e5779d3")
    host.cacheDirectory = "FlickrCache"
    print(NSHomeDirectory())
  }

  func applicationWillTerminate(aNotification: NSNotification) {
    // Insert code here to tear down your application
  }


}

