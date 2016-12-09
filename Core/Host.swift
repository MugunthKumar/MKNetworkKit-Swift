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

let DefaultCacheDuration:TimeInterval = 60 // 1 minute

open class Host: NSObject, URLSessionTaskDelegate, URLSessionDataDelegate, URLSessionDownloadDelegate {

  // MARK:- Properties
  open var name: String?
  fileprivate var path: String?
  fileprivate var portNumber: Int?
  fileprivate var defaultHeaders: [String:String]
  open var defaultParameterEncoding: ParameterEncoding?

  open var secure: Bool = true // ATS, so true! Yay!

  // MARK:- Sessions
  fileprivate var defaultSession: Foundation.URLSession!
  fileprivate var ephermeralSession: Foundation.URLSession!
  fileprivate var backgroundSession: Foundation.URLSession!
  open var backgroundSessionCompletionHandler: ((Void) -> Void)?
  open var backgroundSessionIdentifier: String = "com.mknetworkkit.backgroundsessionidentifier"

  // MARK:- Cache Handling
  open var cacheDirectory: String? {
    didSet {
      if let unwrappedDirectory = cacheDirectory {
        dataCache = Cache(directoryName: "\(unwrappedDirectory)/Data")
        responseCache = Cache(directoryName: "\(unwrappedDirectory)/Response")
        responseTimeCache = Cache(directoryName: "\(unwrappedDirectory)/ResponseTime")
        resumeDataCache = Cache(directoryName: "\(unwrappedDirectory)/ResumeData")
      }
    }
  }

  fileprivate var dataCache: Cache<Data>?
  fileprivate var resumeDataCache: Cache<Data>?
  fileprivate var responseCache: Cache<HTTPURLResponse>?
  fileprivate var responseTimeCache: Cache<Date>?

  open func emptyCache() {
    dataCache?.emptyCache()
    responseCache?.emptyCache()
    responseTimeCache?.emptyCache()
  }

  open var authenticationHandler: ((_ session: Foundation.URLSession, _ task: URLSessionTask,  _ challenge: URLAuthenticationChallenge, _ completionHandler: (Foundation.URLSession.AuthChallengeDisposition, URLCredential?) -> Void) -> Void)?

  // MARK:- Designated Initializer
  public init(name: String? = nil,
    path: String? = nil,
    defaultHeaders: [String:String] = [:],
    portNumber: Int? = nil,
    session: Foundation.URLSession? = nil,
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
        defaultSession = Foundation.URLSession(configuration:
          URLSessionConfiguration.default,
          delegate: self, delegateQueue: OperationQueue.main)
      }

      ephermeralSession = Foundation.URLSession(configuration: URLSessionConfiguration.ephemeral,
        delegate: self, delegateQueue: OperationQueue.main)

      if let name = name {
        backgroundSessionIdentifier = "com.mknetworkkit.backgroundsessionidentifier.\(name)"
      }

      let configuration = URLSessionConfiguration.background(withIdentifier: backgroundSessionIdentifier)
      backgroundSession = Foundation.URLSession(configuration: configuration,
        delegate: self, delegateQueue: OperationQueue.main)
  }

  // MARK:- Request preparation

  open func request(
    _ method: HTTPMethod = .GET,
    withAbsoluteURLString absoluteURLString: String,
             parameters: [String:AnyObject] = [:],
             headers: [String:String] = [:],
             bodyData: Data? = nil) -> Request? {

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

  open func request(
    _ method: HTTPMethod = .GET,
    withPath requestPath: String,
    parameters: [String:Any] = [:],
    headers: [String:String] = [:],
    bodyData: Data? = nil,
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
  @discardableResult
  open func customizeRequest(_ request: Request) -> Request {
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

  open func customizeError(_ request: Request) -> NSError? {
    return request.error
  }

  // MARK:- Running the Request
  open func run(_ request: Request) {
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
            request.responseData = data
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

      request.task = sessionToUse?.dataTask(with: urlRequest)

    } else if request.inputStream != nil {
      request.task = sessionToUse?.uploadTask(withStreamedRequest: urlRequest)
    } else {
      if let resumeData = resumeDataCache?[request.equalityIdentifier] {
        request.task = backgroundSession.downloadTask(withResumeData: resumeData)
      } else {
        request.task = backgroundSession.downloadTask(with: urlRequest)
      }
    }

    request.task!.request = request
    if request.requiresAuthentication {
      ephermeralSession.configuration.urlCredentialStorage?.setDefaultCredential(request.credential!
        , for: request.protectionSpace!, task: request.task!)
    }

    request.state = .Started
  }

  //MARK:- Completion Handler (used for upload and download tasks)
  open func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {

    if task.request!.error == nil { // this could be set if the downloaded file can't be moved
      task.request!.error = error as NSError?
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
      if let data = dataCache?[task.request!.equalityIdentifier] {
        task.request!.responseData = data
      }

    case 400..<600:
      var userInfo = [String:AnyObject]()
      if let unwrappedResponse = task.request!.response {
        userInfo["response"] = unwrappedResponse
      }
      if let unwrappedError = error {
        userInfo["error"] = unwrappedError as AnyObject?
      }
      userInfo[NSLocalizedFailureReasonErrorKey] = "\(statusCode) \(HTTPURLResponse.localizedString(forStatusCode: statusCode))" as AnyObject?
      task.request!.error = NSError(domain: "com.mknetworkkit.httperrordomain", code: statusCode, userInfo: userInfo)
      task.request!.error = self.customizeError(task.request!)

    default:
      break
    }

    if session == backgroundSession {      
      if let infoDictionary = (error as? NSError)?.userInfo {
        resumeDataCache?[task.request!.equalityIdentifier] = infoDictionary[NSURLSessionDownloadTaskResumeData as NSObject] as? Data
      }
    }

    if task.request!.error == nil {
      if session == defaultSession {
        if task.request!.cacheble {
          if statusCode != 304 {
            self.dataCache?[task.request!.equalityIdentifier] = task.request!.responseData
            self.responseCache?[task.request!.equalityIdentifier] = task.request!.response
          }
          self.responseTimeCache?[task.request!.equalityIdentifier] = Date()
        }
      }
      task.request!.state = .Completed
    } else {
      task.request!.state = .Error
    }
  }

  //MARK:- Progress Notifications
  open func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
    let progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
    task.request!.progressValue = progress
  }

  open func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
    let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
    downloadTask.request!.progressValue = progress
  }

  //MARK:- Downloading to File
  open func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {

    guard let path = downloadTask.request!.downloadPath else {
      print ("downloadPath not set in your Request. Unable to move downloaded file")
      return
    }
    do {
      try FileManager.default.moveItem(atPath: location.path, toPath: path)
    } catch let error as NSError {
      downloadTask.request!.error = error
    }
  }

  #if os(macOS)
  #else
  open func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
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
  #endif

  // MARK:- Input Streaming
  open func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
    completionHandler(task.request!.inputStream)
  }

  // MARK:- Output Streaming
  open func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
    // Open streams if any
    for stream in dataTask.request!.outputStream {
      stream.open()
    }
    if dataTask.request!.outputStream.count == 0 {
      dataTask.request!.responseData = Data()
    }

    dataTask.request!.response = response as? HTTPURLResponse
    completionHandler(.allow)
  }

  open func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    for stream in dataTask.request!.outputStream {
      stream.write((data as NSData).bytes.bindMemory(to: UInt8.self, capacity: data.count), maxLength: data.count)
    }
    if dataTask.request!.outputStream.count == 0 {
      dataTask.request!.responseData.append(data)
    }
  }

  // MARK:- Identify and Trust Validation from Certificate
  struct IdentityAndTrust {
    var identityRef:SecIdentity
    var trust:SecTrust
    var certArray:NSArray
  }

  func extractIdentity(_ certData: Data, certPassword: String?) -> IdentityAndTrust {

    var identityAndTrust: IdentityAndTrust!
    var securityError: OSStatus = errSecSuccess

    var items: CFArray?

    var certOptions = [String:String]()
    if let password = certPassword {
      certOptions = [kSecImportExportPassphrase as String: password]
    }
    securityError = SecPKCS12Import(certData as CFData, certOptions as CFDictionary, &items)

    if securityError == errSecSuccess {

      let certItems:CFArray = items as CFArray!
      let certItemsArray:Array = certItems as Array
      let dict:AnyObject? = certItemsArray.first

      if let certEntry:Dictionary = dict as? Dictionary<String, AnyObject> {

        // grab the identity
        let identityPointer:AnyObject? = certEntry["identity"]
        let secIdentityRef:SecIdentity = identityPointer as! SecIdentity!

        // grab the trust
        let trustPointer:AnyObject? = certEntry["trust"]
        let trustRef:SecTrust = trustPointer as! SecTrust

        // grab the certificate chain
        var certRef: SecCertificate?
        SecIdentityCopyCertificate(secIdentityRef, &certRef)
        let certArray = NSMutableArray()
        certArray.add(certRef as SecCertificate!)
        
        identityAndTrust = IdentityAndTrust(identityRef: secIdentityRef, trust: trustRef, certArray: certArray)
      }
    }
    return identityAndTrust
  }

  open func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

    if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
      if let trust = challenge.protectionSpace.serverTrust {
        // TODO: - Add certificate pinning later here
        let credential = URLCredential(trust: trust)
        completionHandler(.useCredential, credential)
      } else {
        completionHandler(.cancelAuthenticationChallenge, nil)
      }
    } else if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodClientCertificate {
      guard let certificate = task.request!.clientCertificate else {
        completionHandler(.cancelAuthenticationChallenge, nil)
        return
      }
      do {
        let certificateData = try Data(contentsOf: URL(fileURLWithPath: certificate), options: .mappedIfSafe)
        let password = task.request!.clientCertificatePassword
        let identityAndTrust:IdentityAndTrust = extractIdentity(certificateData, certPassword: password)
        let urlCredential:URLCredential = URLCredential(identity: identityAndTrust.identityRef,
          certificates: identityAndTrust.certArray as [AnyObject],
          persistence: .forSession)
        completionHandler(.useCredential, urlCredential)
      }
      catch let error as NSError {
        print (error)
        completionHandler(.cancelAuthenticationChallenge, nil)
      }
    } else if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPBasic ||
      challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPDigest ||
      challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodNTLM {
        if challenge.previousFailureCount == 3 {
          completionHandler(.rejectProtectionSpace, nil)
        } else {
          if let credential = session.configuration.urlCredentialStorage?.defaultCredential(for: challenge.protectionSpace) {
            completionHandler(.useCredential, credential)
          } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
          }
        }
    } else if let authenticationHandler = authenticationHandler {
      authenticationHandler(session, task, challenge, completionHandler)
    } else {
      completionHandler(.cancelAuthenticationChallenge, nil)
    }
  }
}
