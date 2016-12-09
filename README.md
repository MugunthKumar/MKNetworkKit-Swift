# MKNetworkKit
#### An simple, elegant and easy to use networking framework in Swift 3.0
[![Build Status](https://travis-ci.org/MugunthKumar/MKNetworkKit-Swift.svg?branch=master)](https://travis-ci.org/MugunthKumar/MKNetworkKit-Swift)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Twitter](https://img.shields.io/badge/twitter-@MugunthKumar-orange.svg?style=flat)](http://twitter.com/MugunthKumar)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/MugunthKumar/MKNetworkKit-Swift/blob/master/LICENSE.md)
[![Supported Platforms](https://img.shields.io/badge/platform-iOS%20%7C%20watch%20OS%20%7C%20tvOS%20%7C%20OSX-yellowgreen.svg)](https://github.com/MugunthKumar/MKNetworkKit-Swift/Wiki)
[![Gitter](https://badges.gitter.im/MugunthKumar/MKNetworkKit-Swift.svg)](https://gitter.im/MugunthKumar/MKNetworkKit-Swift?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

---
This is version 3.0 of MKNetworkKit. 
Version 3 is a complete rewrite loosely based on [version 2](https://github.com/MugunthKumar/MKNetworkKit) that was released in October 2015.

###Why MKNetworkKit?
Actually, you don't need a networking framework today (post iOS 7). We live in the era of `URLSession` and with networking becoming a core feature of every app, you need to know how to write a good networking stack without using a third party library.

Now, you may ask, So, why are there so many networking frameworks? Almost every iOS developer I know uses one or the other networking library.

Well, that's because, when iOS was introduced, the two frameworks built into the iPhone (iOS) SDK, namely, `CFNetwork.framework` and `NSURLConnection`(`Foundation.framework`) were complicated to understand and use.
Though `NSURLConnection` was easier than `CFNetwork` it still wasn't easy enough for most developers.

With iOS 7, Apple introduced `NSURLSession` based networking that blew everything out of water.

Using `URLSession` is super easy to use. Most of today's third party networking frameworks that exist today are built on top of `URLSession`. With deprecation of `NSURLConnection` in iOS 9 (tvOS 9.0 marks NSURLConnection as unavailable), you don't even need to know the "basics" like `NSURLConnection`. In fact, `URLSession` is the new "basics". `URLSession` **is** the class that you should learn, if you are doing networking today.

In my opinion, the only benefits of using a networking framework instead of `URLSession` are 

1. Easier Authentication (`www-authenticate`based and client certificate/server trust based)
	Authentication with NSURLSession still requires delegate handling like NSURLConnection
	
2. Multi-part form upload

In addition to the above, MKNetworkKit has the following features.
* **Queued Requests** (Batch a bunch of requests and get notified once they are done)
* High performance background **caching** (based on HTTP 1.1 caching specs) built in
* Fetching remote images are done using extension methods in strings. Just call the `loadRemoteImage` method on any URL String and get the image in the completion handler. What's more? All these fetched images are automatically cached and you don't need a separate image caching library.
* Auto network indicator support MKNetworkKit manages the display of status bar network indicator for you. (on iOS only)
* cURL-able debug lines
* Fully compatible with application extensions
* Background image decompression
* Background completion
* Full support for NSStreams

---

###Installation
#### Manual
1. Add this repository as a submodule in your project.
2. Drag the `Core` directory into your  project. 
3. Link your project against `SystemConfiguration.framework` if you haven't already

#### Carthage
To integrate MKNetworkKit into your Xcode project using Carthage, specify it in your `Cartfile`:
```
github "MugunthKumar/MKNetworkKit-Swift" "master"
```
Run `carthage update` to build the framework and drag the built `MKNetworkKit.framework` into your Xcode project.

Version 1 of this release is available as a tag [here](https://github.com/MugunthKumar/MKNetworkKit-Swift/tree/v1) for Cocoapods users.

###How to use
Documentation will soon be available on the [wiki page](https://github.com/MugunthKumar/MKNetworkKit-Swift/wiki)

###Licensing
MKNetworkKit is licensed under MIT License. Attribution free licensing is available for a small license fee. Get an attribution free license from our [license store](http://blog.mugunthkumar.com/license-store/)
