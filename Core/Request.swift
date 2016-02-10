//
//  Request.swift
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

public enum ParameterEncoding: String, CustomStringConvertible {
  case URL = "URL"
  case JSON = "JSON"
  public var description: String { return self.rawValue }

  public var contentType: String {
    switch(self) {
    case .URL:
      return "application/x-www-form-urlencoded"
    case .JSON:
      return "application/json"
    }
  }
}

public enum State: String, CustomStringConvertible {
  case Ready = "Ready"
  case Started = "Started"
  case ResponseAvailableFromCache = "ResponseAvailableFromCache"
  case StaleResponseAvailableFromCache = "StaleResponseAvailableFromCache"
  case Cancelled = "Cancelled"
  case Completed = "Completed"
  case Error = "Error"
  public var description: String { return self.rawValue }
}

public enum HTTPMethod: String, CustomStringConvertible {
  case GET = "GET"
  case POST = "POST"
  case PUT = "PUT"
  case DELETE = "DELETE"
  case PATCH = "PATCH"
  case OPTIONS = "OPTIONS"
  case TRACE = "TRACE"
  case CONNECT = "CONNECT"
  public var description: String { return self.rawValue }
}

public enum AuthenticationMethod: RawRepresentable {
  case HTTPBasic
  case HTTPDigest
  public init?(rawValue: String) {
    if rawValue == String(NSURLAuthenticationMethodHTTPDigest) {
      self = HTTPDigest
    }
    else if rawValue == String(NSURLAuthenticationMethodHTTPBasic) {
      self = HTTPBasic
    } else {
      return nil
    }
  }

  public var rawValue: String {
    switch self {
    case .HTTPBasic:
      return String(NSURLAuthenticationMethodHTTPBasic)
    case .HTTPDigest:
      return String(NSURLAuthenticationMethodHTTPDigest)
    }
  }
}

public struct MultipartEntity {
  let mimetype: String
  let suggestedFileName: String
  let data: NSData
  public init(mimetype: String, suggestedFileName: String, data: NSData) {
    self.mimetype = mimetype
    self.suggestedFileName = suggestedFileName
    self.data = data
  }

  public init?(mimetype: String, filePath: String) {
    self.mimetype = mimetype

    guard let fileName = NSURL(fileURLWithPath: filePath).lastPathComponent else {
      return nil
    }
    self.suggestedFileName = fileName

    guard let data = NSData(contentsOfFile: filePath) else {
      return nil
    }
    self.data = data
  }
}

public class Request {
  static private var runningRequestsSynchronizingQueue =
  dispatch_queue_create("com.mknetworkkit.tasks.queue", DISPATCH_QUEUE_SERIAL)
  static private var runningRequests = [Request]()
  static internal var runningRequestsUpdatedHandler: ((Int) -> Void)?

  public var url: String
  public var method: HTTPMethod = .GET
  public var parameters = [String:AnyObject]()
  public var headers = [String:String]()
  public var parameterEncoding: ParameterEncoding = .URL

  public var multipartEntities = [String:MultipartEntity]()
  public var bodyData: NSData?

  public var progress: Double? {
    didSet {
      for handler in progressHandlers {
        handler(self)
      }
    }
  }
  public var task: NSURLSessionTask?
  public weak var host: Host!

  public var username: String?
  public var password: String?
  public var realm: String?
  public var authenticationMethod = AuthenticationMethod.HTTPBasic

  public var clientCertificate: String?
  public var clientCertificatePassword: String?
  
  public var downloadPath: String?

  internal var requiresAuthentication: Bool {
    return (username != nil && password != nil && realm != nil)
  }

  public var doNotCache: Bool = false
  public var ignoreCache: Bool = false
  public var alwaysLoad: Bool = false

  public var state: State = .Ready {
    didSet {
      switch (state) {
      case .Ready:
        break

      case .Started:
        task?.resume()

      case .ResponseAvailableFromCache:
        fallthrough
      case .StaleResponseAvailableFromCache:
        fallthrough
      case .Completed:
        fallthrough
      case .Error:
        if (state == .Error) {
          log()
        }
        if state == .Completed && cachedDataHash != nil {
          if responseData?.md5 == cachedDataHash {
            break
          }
        }
        for handler in completionHandlers {
          handler(self)
        }

      case .Cancelled:
        task?.cancel()
      }

      if (state == .Started) {
        dispatch_async(Request.runningRequestsSynchronizingQueue) {
          Request.runningRequests.append(self)
          Request.runningRequestsUpdatedHandler?(Request.runningRequests.count)
        }
      }
      if (state == .Completed || state == .Error || state == .Cancelled) {
        dispatch_async(Request.runningRequestsSynchronizingQueue) {
          Request.runningRequests = Request.runningRequests.filter {$0 !== self}
          Request.runningRequestsUpdatedHandler?(Request.runningRequests.count)
        }
      }
    }
  }

  var request: NSURLRequest? {
    var finalUrl: String
    switch(method) {
    case .GET, .DELETE, .CONNECT, .TRACE:
      if (parameters.count > 0) {
        finalUrl = url + "?" + parameters.URLEncodedString
      } else {
        finalUrl = url
      }
    case .POST, .PUT, .PATCH, .OPTIONS:
      finalUrl = url
    }

    guard let nsurl = NSURL(string: finalUrl) else {return nil}
    let urlRequest = NSMutableURLRequest(URL: nsurl)
    urlRequest.HTTPMethod = method.description

    for (headerField, headerValue) in headers {
      urlRequest.setValue(headerValue, forHTTPHeaderField: headerField)
    }

    if parameters.count > 0 {
      urlRequest.setValue(parameterEncoding.contentType, forHTTPHeaderField: "Content-Type")
    }

    let charset =
    CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)) as NSString
    urlRequest.addValue("charset=\(charset)", forHTTPHeaderField: "Content-Type")

    if [.POST, .PUT, .PATCH, .OPTIONS].contains(method) {
      urlRequest.HTTPBody = parameters.URLEncodedString.dataUsingEncoding(NSUTF8StringEncoding)
    }

    // this overrides body provided by parameter encoding.
    // for multi-part form data, parameters are encoded differently
    if multipartEntities.count > 0 {
      let body = NSMutableData()
      let boundary = String(format: "multipart-form-boundary.%08x%08x", arc4random(), arc4random())

      for (k, v) in parameters {
        let string = "--\(boundary)\r\nContent-Disposition: form-data; name=\"\(k)\"\r\n\r\n\(v)\r\n"
        body.appendData(string.dataUsingEncoding(NSUTF8StringEncoding)!)
      }

      for (k, v) in multipartEntities {
        let string = "--\(boundary)\r\nContent-Disposition: form-data; name=\"\(k)\"; filename=\"\(v.suggestedFileName)\"\r\nContent-Type: \(v.mimetype)\r\nContent-Transfer-Encoding: binary\r\n\r\n"
        body.appendData(string.dataUsingEncoding(NSUTF8StringEncoding)!)
        body.appendData(v.data)
        body.appendData("\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
      }

      let closingBoundary = "--\(boundary)--\r\n"
      body.appendData(closingBoundary.dataUsingEncoding(NSUTF8StringEncoding)!)

      urlRequest.HTTPBody = body
      urlRequest.setValue("multipart/form-data", forHTTPHeaderField: "Content-Type")
      urlRequest.addValue("charset=\(charset)", forHTTPHeaderField: "Content-Type")
      urlRequest.addValue("boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
      urlRequest.setValue(String(body.length), forHTTPHeaderField: "Content-Length")
    }

    // body data overrides parameters, files or blob based body data
    if let unwrappedBodyData = bodyData {
      urlRequest.HTTPBody = unwrappedBodyData
    }

    return urlRequest
  }

  var credential: NSURLCredential? {
    var credentialToReturn: NSURLCredential? = nil
    if requiresAuthentication {
      credentialToReturn = NSURLCredential(user: username!, password: password!, persistence: .ForSession)
    }
    return credentialToReturn
  }

  var protectionSpace: NSURLProtectionSpace? {
    var protectionSpaceToReturn: NSURLProtectionSpace? = nil

    if let url = request?.URL {
      var portNumber: Int!
      if let p = url.port {
        portNumber = p.integerValue
      } else {
        if url.scheme == "https" {
          portNumber = 443
        } else {
          portNumber = 80
        }
      }
      protectionSpaceToReturn = NSURLProtectionSpace(host: url.host!, port: portNumber,
        `protocol`: url.scheme, realm: realm,
        authenticationMethod: authenticationMethod.rawValue)
    }
    return protectionSpaceToReturn
  }

  var cachedDataHash: String?
  var responseData: NSData?
  var response: NSHTTPURLResponse?

  public var error: NSError?

  var equalityIdentifier: String {
    var string: String = "\(arc4random())"
    if let unwrappedRequest = request {
      if ![.POST, .PUT, .PATCH, .OPTIONS].contains(method) {
        string = "\(method.rawValue.uppercaseString) \(unwrappedRequest.URL!.absoluteString)"
      }
    }
    if let unwrappedUsername = username {
      string += unwrappedUsername
    }
    if let unwrappedPassword = password {
      string += unwrappedPassword
    }
    return string
  }

  var cacheble: Bool {
    if method != .GET {
      return false
    }
    if doNotCache {
      return false
    }
    if requiresAuthentication {
      return false
    }
    return true
  }

  private var progressHandlers = Array<Request -> Void>()
  private var completionHandlers = Array<Request -> Void>()

  init(method: HTTPMethod = .GET,
    url: String,
    parameters: [String:AnyObject] = [:],
    headers: [String:String] = [:],
    bodyData: NSData? = nil) {
      self.url = url
      self.method = method
      self.parameters = parameters
      self.headers = headers
      self.bodyData = bodyData
  }

  public func append(headers additionalHeaders: [String:String] = [:],
    parameters additionalParameters: [String:AnyObject] = [:]) {
      for (k, v) in additionalHeaders {
        headers.updateValue(v, forKey: k)
      }
      for (k, v) in additionalParameters {
        parameters.updateValue(v, forKey: k)
      }
  }

  public func appendHeader(key: String, value: String) {
    headers.updateValue(value, forKey: key)
  }

  public func appendParameter(key: String, value: String) {
    parameters.updateValue(value, forKey: key)
  }

  public func appendMultipartEntity(key: String, value: MultipartEntity) {
    multipartEntities.updateValue(value, forKey: key)
  }

  public func appendBasicAuthorizationHeader(username username: String, password: String) {
    let authString = "\(username):\(password)".dataUsingEncoding(NSUTF8StringEncoding)!.base64EncodedStringWithOptions(.EncodingEndLineWithCarriageReturn)
    appendAuthorizationHeader(type: "Basic", value: authString)
  }
  public func appendAuthorizationHeader(type type: String, value: String) {
    appendHeader("Authorization", value: "\(type) \(value)")
  }

  public var description: String {
    return asCurlCommand
  }

  public var asCurlCommand: String {
    var displayString = "curl -X \(method)"
    guard let r = request else { return displayString }
    guard let urlString = r.URL?.absoluteString else { return displayString }
    displayString = displayString + " '" + urlString + "'"

    guard var h = r.allHTTPHeaderFields else { return displayString }
    if let encodingValue = h["Accept-Encoding"] {
      if encodingValue.containsString("gzip") {
        h["Accept-Encoding"] = nil
      }
    }
    displayString += " -H \(h.map {"'\($0):\($1)'"}.joinWithSeparator(" -H "))"

    if let actualData = r.HTTPBody {
      if let stringData = String(data:actualData, encoding:NSUTF8StringEncoding) {
        displayString = displayString + " -d '" + stringData + "'"
      }
    }
    return displayString
  }

  public var responseAsString: AnyObject? {
    guard let responseData: NSData = responseData else { return nil }
    return String(data: responseData, encoding: NSUTF8StringEncoding)
  }

  public var responseAsJSON: AnyObject? {
    guard let responseData: NSData = responseData else { return nil }
    do {
      let jsonObject = try NSJSONSerialization.JSONObjectWithData(responseData, options: .MutableLeaves)
      return jsonObject
    } catch {
      Log.error("Error parsing as JSON \(responseAsString)")
      return nil
    }
  }

  public func progressChange (handler: (Request) -> Void) -> Request {
    progressHandlers.append(handler)
    return self
  }

  public func completion (handler: (Request) -> Void) -> Request {
    completionHandlers.append(handler)
    return self
  }

  public func log() -> Request {
    Log.info(self.asCurlCommand)
    return self
  }

  public func cancel() -> Request {
    if state == .Started {
      state = .Cancelled
    }
    return self
  }
  
  public func run(alwaysLoad alwaysLoad: Bool? = nil, ignoreCache: Bool? = nil, doNotCache: Bool? = nil) -> Request {
    if let unwrappedAlwaysLoad = alwaysLoad {
      self.alwaysLoad = unwrappedAlwaysLoad
    }
    if let unwrappedIgnoreCache = ignoreCache {
      self.ignoreCache = unwrappedIgnoreCache
    }
    if let unwrappedDoNotCache = doNotCache {
      self.doNotCache = unwrappedDoNotCache
    }
    if self.downloadPath == nil {
      host.startRequest(self)
    } else {
      host.startDownloadRequest(self)
    }
    return self
  }
}