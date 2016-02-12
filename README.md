# MKNetworkKit
#### An simple, elegant and easy to use networking framework in Swift 2.0

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Twitter](https://img.shields.io/badge/twitter-@MugunthKumar-orange.svg?style=flat)](http://twitter.com/MugunthKumar)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/MugunthKumar/MKNetworkKit-Swift/blob/master/LICENSE.md)
[![Supported Platforms](https://img.shields.io/badge/platform-iOS%20%7C%20watch%20OS%20%7C%20tvOS%20%7C%20OSX-yellowgreen.svg)](https://github.com/MugunthKumar/MKNetworkKit-Swift/Wiki)
[![Gitter](https://badges.gitter.im/MugunthKumar/MKNetworkKit-Swift.svg)](https://gitter.im/MugunthKumar/MKNetworkKit-Swift?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

---
This is version 3.0 of MKNetworkKit. 
Version 3 is a complete rewrite loosely based on [version 2](https://github.com/MugunthKumar/MKNetworkKit) that was released in October 2015.

###Why MKNetworkKit?

* Single network queue for the whole app
* Auto queue sizing and auto network indicator support
* High performance background caching (based on HTTP 1.1 caching specs) built in
* You don't need a separate image cache library
* Background image decompression
* Background completion
* cURL-able debug lines

These are just a few of the most interesting features on MKNetworkKit.

---

###Installation
#### Manual
Add this repository as a submodule in your project.
Drag the `Core` directory into your  project. 
Link your project against `SystemConfiguration.framework` if you haven't already

#### Carthage
To integrate MKNetworkKit into your Xcode project using Carthage, specify it in your `Cartfile`:
```
github "MugunthKumar/MKNetworkKit-Swift" "master"
```
Run `carthage update` to build the framework and drag the built `MKNetworkKit.framework` into your Xcode project.

We will release a stable tagged version soon.

###How to use
Documentation is available on the [Wiki page](https://github.com/MugunthKumar/MKNetworkKit-Swift/Wiki)

###Licensing
MKNetworkKit is licensed under MIT License
ATTRIBUTION FREE LICENSING AVAILBLE FOR A LICENSE FEE.
Get an attribution free license here [License Store](http://blog.mugunthkumar.com/license-store/)
