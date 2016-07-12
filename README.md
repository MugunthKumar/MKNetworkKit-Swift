# MKNetworkKit
#### An simple, elegant and easy to use networking framework in Swift 2.0
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
* High performance background caching (based on HTTP 1.1 caching specs) built in
	* You don't need a separate image cache library
* Written completely in Swift 2 and uses Swift like naming conventions. 
	* Your networking code is going to be clean and read like any Swift code
* Auto network indicator support (on iOS only)
	* MKNetworkKit manages the display of status bar network indicator for you
* Fully compatible with application extensions
* Background image decompression
* Background completion
* cURL-able debug lines
* Queued Requests (Batch a bunch of requests and get notified once they are done)
* Full support for NSStreams

These are just a few of the most interesting features on MKNetworkKit.

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

We will release a stable tagged version soon.

###How to use
Documentation is available on the [wiki page](https://github.com/MugunthKumar/MKNetworkKit-Swift/wiki)

###Licensing
MKNetworkKit is licensed under MIT License. Attribution free licensing is available for a small license fee. Get an attribution free license from our [license store](http://blog.mugunthkumar.com/license-store/)
