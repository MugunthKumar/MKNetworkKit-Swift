//
//  Host.swift
//  MKNetworkKit
//
//  Created by Mugunth Kumar
//  Copyright © 2015 - 2020 Steinlogic Consulting and Training Pte Ltd. All rights reserved.
//
//  MIT LICENSE (REQUIRES ATTRIBUTION)
//	ATTRIBUTION FREE LICENSING AVAILBLE (for a license fee)
//  Email mugunth.kumar@gmail.com for details
//
//  Created by Mugunth Kumar (@mugunthkumar)
//  Copyright (C) 2015-2025 by Steinlogic Consulting And Training Pte Ltd.

//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import Foundation

let DefaultCacheDuration:NSTimeInterval = 60 // 1 minute

public class Host: NSObject, NSURLSessionTaskDelegate, NSURLSessionDataDelegate, NSURLSessionDownloadDelegate {

  // MARK:- Properties
  public var name: String?
  private var path: String?
  private var portNumber: Int?
  private var defaultHeaders: [String:String]
  public var defaultParameterEncoding: ParameterEncoding?

  public var secure: Bool = true // ATS, so true! Yay!

  // MARK:- Sessions
  private var defaultSession: NSURLSession!
  private var ephermeralSession: NSURLSession!
  private var backgroundSession: NSURLSession!
  public var backgroundSessionCompletionHandler: (Void -> Void)?
  public var backgroundSessionIdentifier: String = "com.mknetworkkit.backgroundsessionidentifier"

  // MARK:- Cache Handling
  public var cacheDirectory: String? {
    didSet {
      if let unwrappedDirectory = cacheDirectory {
        dataCache = Cache(directoryName: "\(unwrappedDirectory)/Data")
        responseCache = Cache(directoryName: "\(unwrappedDirectory)/Response")
        responseTimeCache = Cache(directoryName: "\(unwrappedDirectory)/ResponseTime")
        resumeDataCache = Cache(directoryName: "\(unwrappedDirectory)/ResumeData")
      }
    }
  }

  private var dataCache: Cache<NSData>?
  private var resumeDataCache: Cache<NSData>?
  private var responseCache: Cache<NSHTTPURLResponse>?
  private var responseTimeCache: Cache<NSDate>?

  public func emptyCache() {
    dataCache?.emptyCache()
    responseCache?.emptyCache()
    responseTimeCache?.emptyCache()
  }

  public var authenticationHandler: ((session: NSURLSession, task: NSURLSessionTask,  challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) -> Void)?

  // MARK:- Designated Initializer
  public init(name: String? = nil,
    path: String? = nil,
    defaultHeaders: [String:String] = [:],
    portNumber: Int? = nil,
    session: NSURLSession? = nil,
    cacheDirectory: String? = nil,
    cacheCost: Int = 50) {

      self.name = name
      self.defaultHeaders = defaultHeaders
      self.path = path
      self.portNumber = portNumber

      if let unwrappedDirectory = cacheDirectory {
        self.cacheDirectory = unwrappedDirectory
        dataCache = Cache(cost: cacheCost, directoryName: "\(unwrappedDirectory)/Data")
        responseCache = Cache(cost: cacheCost, directoryName: "\(unwrappedDirectory)/Response")
        responseTimeCache = Cache(cost: cacheCost, directoryName: "\(unwrappedDirectory)/ResponseTime")
        resumeDataCache = Cache(cost: cacheCost, directoryName: "\(unwrappedDirectory)/ResumeData")
      } else {
        resumeDataCache = Cache(cost: cacheCost)
      }

      super.init()

      if let s = session {
        defaultSession = s
      } else {
        defaultSession = NSURLSession(configuration:
          NSURLSessionConfiguration.defaultSessionConfiguration(),
          delegate: self, delegateQueue: NSOperationQueue.mainQueue())
      }

      ephermeralSession = NSURLSession(configuration: NSURLSessionConfiguration.ephemeralSessionConfiguration(),
        delegate: self, delegateQueue: NSOperationQueue.mainQueue())

      if let name = name {
        backgroundSessionIdentifier = "com.mknetworkkit.backgroundsessionidentifier.\(name)"
      }

      let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(backgroundSessionIdentifier)
      backgroundSession = NSURLSession(configuration: configuration,
        delegate: self, delegateQueue: NSOperationQueue.mainQueue())
  }

  // MARK:- Request preparation

  public func request(
    method: HTTPMethod = .GET,
    withAbsoluteURLString absoluteURLString: String,
             parameters: [String:AnyObject] = [:],
             headers: [String:String] = [:],
             bodyData: NSData? = nil) -> Request? {

    let request = Request(
      method: method,
      url: absoluteURLString,
      parameters: parameters,
      headers: headers,
      bodyData: bodyData)

    request.host = self // weak reference
    request.append(headers: defaultHeaders)
    if let defaultParameterEncoding = defaultParameterEncoding {
      request.parameterEncoding = defaultParameterEncoding
    }
    return customizeRequest(request)
  }

  public func request(
    method: HTTPMethod = .GET,
    withPath requestPath: String,
    parameters: [String:AnyObject] = [:],
    headers: [String:String] = [:],
    bodyData: NSData? = nil,
    ssl: Bool? = nil) -> Request? {

      var httpProtocol: String!

      if let unwrappedSSL = ssl {
        httpProtocol = unwrappedSSL ? "https://" : "http://"
      } else {
        httpProtocol = secure ? "https://" : "http://"
      }

      guard let hostName = name else {
        Log.error("Host name is nil. To create a request with absolute URL use request(withUrlString:)")
        return nil
      }

      var finalUrl: String = httpProtocol + hostName

      if let unwrappedPortNumber = portNumber {
        finalUrl = finalUrl + ":\(unwrappedPortNumber)"
      }

      if let unwrappedPath = self.path {
        finalUrl = finalUrl + "/\(unwrappedPath)"
      }

      finalUrl = finalUrl + "/\(requestPath)"

      let request = Request(
        method: method,
        url: finalUrl,
        parameters: parameters,
        headers: headers,
        bodyData: bodyData)

      request.host = self // weak reference
      request.append(headers: defaultHeaders)
      if let defaultParameterEncoding = defaultParameterEncoding {
        request.parameterEncoding = defaultParameterEncoding
      }
      return customizeRequest(request)
  }

  // MARK:- Customization Opportunities for Subclasses
  public func customizeRequest(request: Request) -> Request {
    if !request.cacheble || request.ignoreCache {
      return request
    }
    if let cachedResponse = responseCache?[request.equalityIdentifier] {
      if let lastModified = cachedResponse.headerValue("Last-Modified") {
        request.appendHeader("IF-MODIFIED-SINCE", value: lastModified)
      }
      if let eTag = cachedResponse.headerValue("ETag") {
        request.appendHeader("IF-NONE-MATCH", value: eTag)
      }
    }
    return request
  }

  public func customizeError(request: Request) -> NSError? {
    return request.error
  }

  // MARK:- Running the Request
  public func run(request: Request) {
    guard let urlRequest = request.request else {
      Log.error("Request is nil, check your URL and other parameters you use to build your request")
      return
    }

    let sessionToUse = request.requiresAuthentication ? ephermeralSession: defaultSession

    if request.downloadPath == nil { // create a data task
      if request.cacheble && !request.ignoreCache {
        if let cachedResponse = responseCache?[request.equalityIdentifier] {
          let date = responseTimeCache?[request.equalityIdentifier]
          let cacheExpiryDate = cachedResponse.cacheExpiryDate(date)
          let expiryTimeFromNow = cacheExpiryDate?.timeIntervalSinceNow ?? DefaultCacheDuration

          if let data = dataCache?[request.equalityIdentifier] {
            request.responseData = data.mutableCopy() as! NSMutableData
            request.response = cachedResponse
            request.cachedDataHash = data.md5

            if expiryTimeFromNow > 0 {
              request.state = .ResponseAvailableFromCache
              request.cachedDataHash = data.md5

              if !request.alwaysLoad {
                request.state = .Completed
                return
              }
            } else {
              request.state = .StaleResponseAvailableFromCache
            }
          }
        }
      }

      request.task = sessionToUse.dataTaskWithRequest(urlRequest)

    } else if request.inputStream != nil {
      request.task = sessionToUse.uploadTaskWithStreamedRequest(urlRequest)
    } else {
      if let resumeData = resumeDataCache?[request.equalityIdentifier] {
        request.task = backgroundSession.downloadTaskWithResumeData(resumeData)
      } else {
        request.task = backgroundSession.downloadTaskWithRequest(urlRequest)
      }
    }

    request.task!.request = request
    if request.requiresAuthentication {
      ephermeralSession.configuration.URLCredentialStorage?.setDefaultCredential(request.credential!
        , forProtectionSpace: request.protectionSpace!, task: request.task!)
    }

    request.state = .Started
  }

  //MARK:- Completion Handler (used for upload and download tasks)
  public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {

    if task.request!.error == nil { // this could be set if the downloaded file can't be moved
      task.request!.error = error
    }

    if task.request!.state == .Cancelled {
      return
    }

    if task.request!.response == nil {
      task.request!.state = .Error
      return
    }

    for stream in task.request!.outputStream {
      stream.close()
    }

    var statusCode: Int = 0
    if let response = task.request!.response {
      statusCode = response.statusCode
    }

    switch (statusCode) {
    case 304:
      task.request!.responseData = NSMutableData() // clear the data

    case 400..<600:
      var userInfo = [String:AnyObject]()
      if let unwrappedResponse = task.request!.response {
        userInfo["response"] = unwrappedResponse
      }
      if let unwrappedError = error {
        userInfo["error"] = unwrappedError
      }
      userInfo[NSLocalizedFailureReasonErrorKey] = "\(statusCode) " + NSHTTPURLResponse.localizedStringForStatusCode(statusCode)
      task.request!.error = NSError(domain: "com.mknetworkkit.httperrordomain", code: statusCode, userInfo: userInfo)
      task.request!.error = self.customizeError(task.request!)

    default:
      break
    }

    if session == backgroundSession {
      if let infoDictionary = error?.userInfo {
        resumeDataCache?[task.request!.equalityIdentifier] = infoDictionary[NSURLSessionDownloadTaskResumeData as NSObject] as? NSData
      }
    }

    if task.request!.error == nil {
      if session == defaultSession {
        if task.request!.cacheble {
          if statusCode != 304 {
            self.dataCache?[task.request!.equalityIdentifier] = task.request!.responseData
            self.responseCache?[task.request!.equalityIdentifier] = task.request!.response
            self.responseTimeCache?[task.request!.equalityIdentifier] = NSDate()
          }
        }
      }
      task.request!.state = .Completed
    } else {
      task.request!.state = .Error
    }
  }

  //MARK:- Progress Notifications
  public func URLSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
    let progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
    task.request!.progressValue = progress
  }

  public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
    let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
    downloadTask.request!.progressValue = progress
  }

  //MARK:- Downloading to File
  public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {

    guard let path = downloadTask.request!.downloadPath else {
      print ("downloadPath not set in your Request. Unable to move downloaded file")
      return
    }
    do {
      try NSFileManager.defaultManager().moveItemAtPath(location.path!, toPath: path)
    } catch let error as NSError {
      downloadTask.request!.error = error
    }
  }

  public func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
    if session != backgroundSession {
      return
    }
    backgroundSession.getTasksWithCompletionHandler {[unowned self] (dataTasks, uploadTasks, downloadTasks) -> Void in
      if dataTasks.count + uploadTasks.count + downloadTasks.count == 0 {
        self.backgroundSessionCompletionHandler?()
        self.backgroundSessionCompletionHandler = nil
      }
    }
  }

  // MARK:- Input Streaming
  public func URLSession(session: NSURLSession, task: NSURLSessionTask, needNewBodyStream completionHandler: (NSInputStream?) -> Void) {
    completionHandler(task.request!.inputStream)
  }

  // MARK:- Output Streaming
  public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
    // Open streams if any
    for stream in dataTask.request!.outputStream {
      stream.open()
    }
    if dataTask.request!.outputStream.count == 0 {
      dataTask.request!.responseData = NSMutableData()
    }

    dataTask.request!.response = response as? NSHTTPURLResponse
    completionHandler(.Allow)
  }

  public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
    for stream in dataTask.request!.outputStream {
      stream.write(UnsafePointer<UInt8>(data.bytes), maxLength: data.length)
    }
    if dataTask.request!.outputStream.count == 0 {
      dataTask.request!.responseData.appendData(data)
    }
  }

  // MARK:- Identify and Trust Validation from Certificate
  struct IdentityAndTrust {
    var identityRef:SecIdentityRef
    var trust:SecTrustRef
    var certArray:NSArray
  }

  func extractIdentity(certData: NSData, certPassword: String?) -> IdentityAndTrust {

    var identityAndTrust: IdentityAndTrust!
    var securityError: OSStatus = errSecSuccess

    var items: CFArray?

    var certOptions = [:]
    if let password = certPassword {
      certOptions = [kSecImportExportPassphrase as String: password]
    }
    securityError = SecPKCS12Import(certData, certOptions, &items)

    if securityError == errSecSuccess {

      let certItems:CFArray = items as CFArray!
      let certItemsArray:Array = certItems as Array
      let dict:AnyObject? = certItemsArray.first

      if let certEntry:Dictionary = dict as? Dictionary<String, AnyObject> {

        // grab the identity
        let identityPointer:AnyObject? = certEntry["identity"]
        let secIdentityRef:SecIdentityRef = identityPointer as! SecIdentityRef!

        // grab the trust
        let trustPointer:AnyObject? = certEntry["trust"]
        let trustRef:SecTrustRef = trustPointer as! SecTrustRef

        // grab the certificate chain
        var certRef: SecCertificate?
        SecIdentityCopyCertificate(secIdentityRef, &certRef)
        let certArray = NSMutableArray()
        certArray.addObject(certRef as SecCertificateRef!)
        
        identityAndTrust = IdentityAndTrust(identityRef: secIdentityRef, trust: trustRef, certArray: certArray)
      }
    }
    return identityAndTrust
  }

  public func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {

    if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
      if let trust = challenge.protectionSpace.serverTrust {
        // TODO: - Add certificate pinning later here
        let credential = NSURLCredential(forTrust: trust)
        completionHandler(.UseCredential, credential)
      } else {
        completionHandler(.CancelAuthenticationChallenge, nil)
      }
    } else if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodClientCertificate {
      guard let certificate = task.request!.clientCertificate else {
        completionHandler(.CancelAuthenticationChallenge, nil)
        return
      }
      do {
        let certificateData = try NSData(contentsOfFile: certificate, options: .DataReadingMappedIfSafe)
        let password = task.request!.clientCertificatePassword
        let identityAndTrust:IdentityAndTrust = extractIdentity(certificateData, certPassword: password)
        let urlCredential:NSURLCredential = NSURLCredential(identity: identityAndTrust.identityRef,
          certificates: identityAndTrust.certArray as [AnyObject],
          persistence: .ForSession)
        completionHandler(.UseCredential, urlCredential)
      }
      catch let error as NSError {
        print (error)
        completionHandler(.CancelAuthenticationChallenge, nil)
      }
    } else if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPBasic ||
      challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPDigest ||
      challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodNTLM {
        if challenge.previousFailureCount == 3 {
          completionHandler(.RejectProtectionSpace, nil)
        } else {
          if let credential = session.configuration.URLCredentialStorage?.defaultCredentialForProtectionSpace(challenge.protectionSpace) {
            completionHandler(.UseCredential, credential)
          } else {
            completionHandler(.CancelAuthenticationChallenge, nil)
          }
        }
    } else if let authenticationHandler = authenticationHandler {
      authenticationHandler(session: session, task: task, challenge: challenge, completionHandler: completionHandler)
    } else {
      completionHandler(.CancelAuthenticationChallenge, nil)
    }
  }
}