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

// MARK: Parameter Encoding
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

// MARK:- State
public enum State: String, CustomStringConvertible {
  case Ready = "Ready"
  case Started = "Started"
  case ResponseAvailableFromCache = "ResponseAvailableFromCache"
  case StaleResponseAvailableFromCache = "StaleResponseAvailableFromCache"
  case Paused = "Paused"
  case Cancelled = "Cancelled"
  case Completed = "Completed"
  case Error = "Error"
  public var description: String { return self.rawValue }
}

// MARK:- HTTP Method
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

// MARK:- Authentication Method
public enum AuthenticationMethod: RawRepresentable {
  case httpBasic
  case httpDigest
  public init?(rawValue: String) {
    if rawValue == String(NSURLAuthenticationMethodHTTPDigest) {
      self = .httpDigest
    }
    else if rawValue == String(NSURLAuthenticationMethodHTTPBasic) {
      self = .httpBasic
    } else {
      return nil
    }
  }

  public var rawValue: String {
    switch self {
    case .httpBasic:
      return String(NSURLAuthenticationMethodHTTPBasic)
    case .httpDigest:
      return String(NSURLAuthenticationMethodHTTPDigest)
    }
  }
}

// MARK:- Multipart Entity
public struct MultipartEntity {
  let mimetype: String
  let suggestedFileName: String
  let data: Data
  public init(mimetype: String, suggestedFileName: String, data: Data) {
    self.mimetype = mimetype
    self.suggestedFileName = suggestedFileName
    self.data = data
  }

  public init?(mimetype: String, filePath: String) {
    self.mimetype = mimetype
    self.suggestedFileName = URL(fileURLWithPath: filePath).lastPathComponent

    guard let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else {
      return nil
    }
    self.data = data
  }
}

open class Request: NSObject {

  // MARK:- Properties to manage Running Requests
  static fileprivate var runningRequestsSynchronizingQueue =
  DispatchQueue(label: "com.mknetworkkit.request.queue", attributes: [])
  static fileprivate var runningRequests = [Request]()
  static internal var runningRequestsUpdatedHandler: ((Int) -> Void)?

  // MARK:- URL Properties
  internal var url: String
  internal var method = HTTPMethod.GET
  internal var parameters = [String:Any]()
  internal var headers = [String:String]()
  open var parameterEncoding = ParameterEncoding.URL

  internal var multipartEntities = [String:MultipartEntity]()
  internal var bodyData: Data?

  // MARK:- Stream Properties
  open var inputStream: InputStream?
  internal var outputStream = [OutputStream]()
  open var downloadPath: String?

  // MARK:- Opaque References
  internal weak var task: URLSessionTask?
  internal weak var host: Host!

  // MARK:- Authentication Properties
  open var username: String?
  open var password: String?
  open var realm: String?
  open var authenticationMethod = AuthenticationMethod.httpBasic
  open var clientCertificate: String?
  open var clientCertificatePassword: String?

  internal var requiresAuthentication: Bool {
    return (username != nil && password != nil && realm != nil)
  }

  open var credential: URLCredential? {
    var credentialToReturn: URLCredential? = nil
    if requiresAuthentication {
      credentialToReturn = URLCredential(user: username!, password: password!, persistence: .forSession)
    }
    return credentialToReturn
  }

  open var protectionSpace: URLProtectionSpace? {
    var protectionSpaceToReturn: URLProtectionSpace? = nil

    if let url = request?.url {
      var portNumber: Int!
      if let p = (url as NSURL).port {
        portNumber = p.intValue
      } else {
        if url.scheme == "https" {
          portNumber = 443
        } else {
          portNumber = 80
        }
      }
      protectionSpaceToReturn = URLProtectionSpace(host: url.host!, port: portNumber,
        protocol: url.scheme, realm: realm,
        authenticationMethod: authenticationMethod.rawValue)
    }
    return protectionSpaceToReturn
  }

  // MARK:- State Change Handlers
  open var stateWillChange: ((Request) -> Void)?
  open var stateDidChange: ((Request) -> Void)?

  // MARK:- Progress And Completion Handlers
  fileprivate var progressHandlers = Array<(Request) -> Void>()
  fileprivate var completionHandlers = Array<(Request) -> Void>()

  open var progressValue: Double? {
    didSet {
      for handler in progressHandlers {
        handler(self)
      }
    }
  }

  // MARK:- Cache Handling Properties
  open var doNotCache: Bool = false
  open var ignoreCache: Bool = false
  open var alwaysLoad: Bool = false

  internal var cachedDataHash: String?
  internal var equalityIdentifier: String {
    var string: String = "\(arc4random())"
    if let unwrappedRequest = request {
      if ![.POST, .PUT, .PATCH, .OPTIONS].contains(method) {
        string = "\(method.rawValue.uppercased())-\(unwrappedRequest.url!.absoluteString)"
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

  internal var cacheble: Bool {
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

  // MARK:- Request State
  @discardableResult
  open func cancel() -> Request {
    if state == .Started {
      state = .Cancelled
    }
    return self
  }

  @discardableResult
  open func pause() -> Request {
    if state == .Started {
      state = .Paused
    }
    return self
  }

  @discardableResult
  open func resume() -> Request {
    if state == .Paused {
      state = .Started
    }
    return self
  }

  open var state: State = .Ready {
    willSet {
      stateWillChange?(self)
    }
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
          if responseData.md5 == cachedDataHash {
            break
          }
        }
        for handler in completionHandlers {
          handler(self)
        }

      case .Paused:
        task?.suspend()

      case .Cancelled:
        task?.cancel()
      }

      stateDidChange?(self)

      if (state == .Started) {
        Request.runningRequestsSynchronizingQueue.async {
          Request.runningRequests.append(self)
          Request.runningRequestsUpdatedHandler?(Request.runningRequests.count)
        }
      }
      if (state == .Completed || state == .Paused || state == .Error || state == .Cancelled) {
        Request.runningRequestsSynchronizingQueue.async {
          Request.runningRequests = Request.runningRequests.filter {$0 !== self}
          Request.runningRequestsUpdatedHandler?(Request.runningRequests.count)
        }
      }
    }
  }

  // MARK:- URL Request Preparation
  open var request: URLRequest? {
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

    guard let nsurl = URL(string: finalUrl) else {return nil}
    let urlRequest = NSMutableURLRequest(url: nsurl)
    urlRequest.httpMethod = method.description

    for (headerField, headerValue) in headers {
      urlRequest.setValue(headerValue, forHTTPHeaderField: headerField)
    }

    let charset =
    CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(String.Encoding.utf8.rawValue)) as NSString
    
    if parameters.count > 0 && urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
      urlRequest.setValue(parameterEncoding.contentType, forHTTPHeaderField: "Content-Type")
      urlRequest.addValue("charset=\(charset)", forHTTPHeaderField: "Content-Type")
    }

    if [.POST, .PUT, .PATCH, .OPTIONS].contains(method) {
      if parameterEncoding == .URL {
        urlRequest.httpBody = parameters.URLEncodedString.data(using: String.Encoding.utf8)
      }
      if parameterEncoding == .JSON {
        urlRequest.httpBody = parameters.JSONString?.data(using: String.Encoding.utf8)
      }
    }

    // this overrides body provided by parameter encoding.
    // for multi-part form data, parameters are encoded differently
    if multipartEntities.count > 0 {
      let body = NSMutableData()
      let boundary = String(format: "multipart-form-boundary.%08x%08x", arc4random(), arc4random())

      for (k, v) in parameters {
        let string = "--\(boundary)\r\nContent-Disposition: form-data; name=\"\(k)\"\r\n\r\n\(v)\r\n"
        body.append(string.data(using: String.Encoding.utf8)!)
      }

      for (k, v) in multipartEntities {
        let string = "--\(boundary)\r\nContent-Disposition: form-data; name=\"\(k)\"; filename=\"\(v.suggestedFileName)\"\r\nContent-Type: \(v.mimetype)\r\nContent-Transfer-Encoding: binary\r\n\r\n"
        body.append(string.data(using: String.Encoding.utf8)!)
        body.append(v.data)
        body.append("\r\n".data(using: String.Encoding.utf8)!)
      }

      let closingBoundary = "--\(boundary)--\r\n"
      body.append(closingBoundary.data(using: String.Encoding.utf8)!)

      urlRequest.httpBody = body as Data
      urlRequest.setValue("multipart/form-data", forHTTPHeaderField: "Content-Type")
      urlRequest.addValue("charset=\(charset)", forHTTPHeaderField: "Content-Type")
      urlRequest.addValue("boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
      urlRequest.setValue(String(body.length), forHTTPHeaderField: "Content-Length")
    }

    // body data overrides parameters, files or blob based body data
    if let unwrappedBodyData = bodyData {
      urlRequest.httpBody = unwrappedBodyData
    }

    return urlRequest as URLRequest
  }

  // MARK:- Response Properties
  internal var responseData = Data()
  internal var response: HTTPURLResponse?
  open var error: NSError?

  // MARK:- Designated Initializer
  init(method: HTTPMethod = .GET,
    url: String,
    parameters: [String:Any] = [:],
    headers: [String:String] = [:],
    bodyData: Data? = nil) {
      self.url = url
      self.method = method
      self.parameters = parameters
      self.headers = headers
      self.bodyData = bodyData
  }

  // MARK:- Tweaking your Request
  open func append(headers additionalHeaders: [String:String] = [:],
    parameters additionalParameters: [String:AnyObject] = [:]) {
      for (k, v) in additionalHeaders {
        headers.updateValue(v, forKey: k)
      }
      for (k, v) in additionalParameters {
        parameters.updateValue(v, forKey: k)
      }
  }

  open func appendHeader(_ key: String, value: String) {
    headers.updateValue(value, forKey: key)
  }

  open func appendParameter(_ key: String, value: String) {
    parameters.updateValue(value as AnyObject, forKey: key)
  }

  open func appendMultipartEntity(_ key: String, value: MultipartEntity) {
    multipartEntities.updateValue(value, forKey: key)
  }

  open func appendOutputStream(_ stream: OutputStream) {
    outputStream.append(stream)
  }

  // MARK:- Adding Authorization to your Request
  open func appendBasicAuthorizationHeader(username: String, password: String) {
    let authString = "\(username):\(password)".data(using: String.Encoding.utf8)!.base64EncodedString(options: .endLineWithCarriageReturn)
    appendAuthorizationHeader(type: "Basic", value: authString)
  }
  open func appendAuthorizationHeader(type: String, value: String) {
    appendHeader("Authorization", value: "\(type) \(value)")
  }

  // MARK:- Printing and Debug String Support
  open override var description: String {
    return asCurlCommand
  }

  open var asCurlCommand: String {
    var displayString = "curl -X \(method)"
    guard let r = request else { return displayString }
    guard let urlString = r.url?.absoluteString else { return displayString }
    displayString = displayString + " '" + urlString + "'"

    guard var h = r.allHTTPHeaderFields else { return displayString }
    if let encodingValue = h["Accept-Encoding"] {
      if encodingValue.contains("gzip") {
        h["Accept-Encoding"] = nil
      }
    }
    displayString += " -H \(h.map {"'\($0):\($1)'"}.joined(separator: " -H "))"

    if let actualData = r.httpBody {
      if let stringData = String(data:actualData, encoding:String.Encoding.utf8) {
        displayString = displayString + " -d '" + stringData + "'"
      }
    }
    return displayString
  }

  @discardableResult
  open func log() -> Request {
    Log.info(self.asCurlCommand)
    return self
  }

  // MARK:- Response Formatters
  open var responseAsString: String? {
    return String(data: responseData, encoding: String.Encoding.utf8)
  }

  open var responseAsJSON: AnyObject? {
    do {
      let jsonObject = try JSONSerialization.jsonObject(with: responseData, options: .mutableLeaves)
      return jsonObject as AnyObject?
    } catch {
      Log.error("Error parsing as JSON \(responseAsString)")
      return nil
    }
  }

  @discardableResult
  open func progress (_ handler: @escaping (Request) -> Void) -> Request {
    progressHandlers.append(handler)
    return self
  }

  @discardableResult
  open func completion (_ handler: @escaping (Request) -> Void) -> Request {
    completionHandlers.append(handler)
    return self
  }

  // MARK:- Running the request
  @discardableResult
  open func run(alwaysLoad: Bool? = nil, ignoreCache: Bool? = nil, doNotCache: Bool? = nil) -> Request {
    if let unwrappedAlwaysLoad = alwaysLoad {
      self.alwaysLoad = unwrappedAlwaysLoad
    }
    if let unwrappedIgnoreCache = ignoreCache {
      self.ignoreCache = unwrappedIgnoreCache
    }
    if let unwrappedDoNotCache = doNotCache {
      self.doNotCache = unwrappedDoNotCache
    }
    host.run(self)
    return self
  }
}
