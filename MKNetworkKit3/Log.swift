//
//  Log.swift
//  MKNetworkKitDemo
//  19 Jun 2015

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

struct Log {

  static let emojiLogger = Log(
    infoPrefix: "✅",
    infoSuffix: "✅",
    warnPrefix: "⚠️",
    warnSuffix: "⚠️",
    errorPrefix: "🚫",
    errorSuffix: "🚫"
  )

  static let xcodeColorsLogger = Log(
    infoPrefix: "\u{001b}[fg0,255,0;",
    infoSuffix: "\u{001b}[;",
    warnPrefix: "\u{001b}[fg255,255,0;",
    warnSuffix: "\u{001b}[;",
    errorPrefix: "\u{001b}[fg255,0,0;",
    errorSuffix: "\u{001b}[;"
  )

  static var defaultLogger : Log = emojiLogger

  var infoPrefix : String
  var warnPrefix : String
  var errorPrefix : String
  var infoSuffix : String
  var warnSuffix : String
  var errorSuffix : String

  init(infoPrefix : String, infoSuffix : String,
    warnPrefix : String, warnSuffix : String,
    errorPrefix : String, errorSuffix : String
    ) {

      setenv("XcodeColors", "YES", 0)

      self.infoPrefix = infoPrefix
      self.warnPrefix = warnPrefix
      self.errorPrefix = errorPrefix

      self.infoSuffix = infoSuffix
      self.warnSuffix = warnSuffix
      self.errorSuffix = errorSuffix
  }

  func info<T>(object : T, functionName : String = __FUNCTION__, lineNumber : Int = __LINE__) {

    print("\(functionName) [\(lineNumber)] \(infoPrefix)\(object)\(infoSuffix)")
  }

  func warn<T>(object : T, functionName : String = __FUNCTION__, lineNumber : Int = __LINE__) {

    print("\(functionName) [\(lineNumber)] \(warnPrefix)\(object)\(warnSuffix)")
  }

  func error<T>(object : T, functionName : String = __FUNCTION__, lineNumber : Int = __LINE__) {

    print("\(functionName) [\(lineNumber)] \(errorPrefix)\(object)\(errorSuffix)")
  }

  static func info<T>(object : T, functionName : String = __FUNCTION__, lineNumber : Int = __LINE__) {

    defaultLogger.info(object, functionName:functionName, lineNumber:lineNumber)
  }

  static func warn<T>(object : T, functionName : String = __FUNCTION__, lineNumber : Int = __LINE__) {

    defaultLogger.warn(object, functionName:functionName, lineNumber:lineNumber)
  }

  static func error<T>(object : T, functionName : String = __FUNCTION__, lineNumber : Int = __LINE__) {

    defaultLogger.error(object, functionName:functionName, lineNumber:lineNumber)
  }
}