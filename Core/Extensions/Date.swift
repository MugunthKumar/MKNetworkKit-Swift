//
//  NSDate+RFC1123.swift
//
//
//  Created by Foster Yin on 9/30/15.
//  Copyright © 2015 Foster Yin. All rights reserved.
//
//  http://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html#sec3.3.1
//  http://www.unicode.org/reports/tr35/tr35-31/tr35-dates.html#Date_Format_Patterns
//  http://blog.mro.name/2009/08/nsdateformatter-http-header/
//  http://stackoverflow.com/questions/8636754/nsdate-to-rfc-2822-date-format
//  http://nshipster.com/nsformatter/

import Foundation

public extension Date {

  fileprivate static func cachedThreadLocalObjectWithKey<T: AnyObject>(_ key: String, create: () -> T) -> T {
    let threadDictionary = Thread.current.threadDictionary
    if let cachedObject = threadDictionary[key] as! T? {
      return cachedObject
    }
    else {
      let newObject = create()
      threadDictionary[key] = newObject
      return newObject
    }
  }

  fileprivate static func RFC1123DateFormatter() -> DateFormatter {
    return cachedThreadLocalObjectWithKey("RFC1123DateFormatter") {
      let locale = Locale(identifier: "en_US")
      let timeZone = TimeZone(identifier: "GMT")
      let dateFormatter = DateFormatter()
      dateFormatter.locale = locale
      dateFormatter.timeZone = timeZone
      dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
      return dateFormatter
    }
  }

  fileprivate static func RFC850DateFormatter() -> DateFormatter {
    return cachedThreadLocalObjectWithKey("RFC850DateFormatter") {
      let locale = Locale(identifier: "en_US")
      let timeZone = TimeZone(identifier: "GMT")
      let dateFormatter = DateFormatter()
      dateFormatter.locale = locale
      dateFormatter.timeZone = timeZone
      dateFormatter.dateFormat = "EEEE, dd-MMM-yy HH:mm:ss z"
      return dateFormatter
    }
  }

  fileprivate static func asctimeDateFormatter() -> DateFormatter {
    return cachedThreadLocalObjectWithKey("asctimeDateFormatter") {
      let locale = Locale(identifier: "en_US")
      let timeZone = TimeZone(identifier: "GMT")
      let dateFormatter = DateFormatter()
      dateFormatter.locale = locale
      dateFormatter.timeZone = timeZone
      dateFormatter.dateFormat = "EEE MMM d HH:mm:ss yyyy"
      return dateFormatter
    }
  }

  public static func dateFromRFC1123DateString(_ dateString:String) -> Date? {

    var date:Date?
    //RFC1123
    date = Date.RFC1123DateFormatter().date(from: dateString)
    if date != nil {
      return date
    }

    //RFC850
    date = Date.RFC850DateFormatter().date(from: dateString)
    if date != nil {
      return date
    }

    //asctime-date
    date = Date.asctimeDateFormatter().date(from: dateString)
    if date != nil {
      return date
    }
    return nil
  }

  public func toRFC1123String() -> String? {
    return Date.RFC1123DateFormatter().string(from: self)
  }
}
