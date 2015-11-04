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

extension NSDate {

  private static func cachedThreadLocalObjectWithKey<T: AnyObject>(key: String, create: () -> T) -> T {
    let threadDictionary = NSThread.currentThread().threadDictionary
    if let cachedObject = threadDictionary[key] as! T? {
      return cachedObject
    }
    else {
      let newObject = create()
      threadDictionary[key] = newObject
      return newObject
    }
  }

  private static func RFC1123DateFormatter() -> NSDateFormatter {
    return cachedThreadLocalObjectWithKey("RFC1123DateFormatter") {
      let locale = NSLocale(localeIdentifier: "en_US")
      let timeZone = NSTimeZone(name: "GMT")
      let dateFormatter = NSDateFormatter()
      dateFormatter.locale = locale //need locale for some iOS 9 verision, will not select correct default locale
      dateFormatter.timeZone = timeZone
      dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
      return dateFormatter
    }
  }

  private static func RFC850DateFormatter() -> NSDateFormatter {
    return cachedThreadLocalObjectWithKey("RFC850DateFormatter") {
      let locale = NSLocale(localeIdentifier: "en_US")
      let timeZone = NSTimeZone(name: "GMT")
      let dateFormatter = NSDateFormatter()
      dateFormatter.locale = locale //need locale for some iOS 9 verision, will not select correct default locale
      dateFormatter.timeZone = timeZone
      dateFormatter.dateFormat = "EEEE, dd-MMM-yy HH:mm:ss z"
      return dateFormatter
    }
  }

  private static func asctimeDateFormatter() -> NSDateFormatter {
    return cachedThreadLocalObjectWithKey("asctimeDateFormatter") {
      let locale = NSLocale(localeIdentifier: "en_US")
      let timeZone = NSTimeZone(name: "GMT")
      let dateFormatter = NSDateFormatter()
      dateFormatter.locale = locale //need locale for some iOS 9 verision, will not select correct default locale
      dateFormatter.timeZone = timeZone
      dateFormatter.dateFormat = "EEE MMM d HH:mm:ss yyyy"
      return dateFormatter
    }
  }

  public static func dateFromRFC1123DateString(dateString:String) -> NSDate? {

    var date:NSDate?
    //RFC1123
    date = NSDate.RFC1123DateFormatter().dateFromString(dateString)
    if date != nil {
      return date
    }

    //RFC850
    date = NSDate.RFC850DateFormatter().dateFromString(dateString)
    if date != nil {
      return date
    }

    //asctime-date
    date = NSDate.asctimeDateFormatter().dateFromString(dateString)
    if date != nil {
      return date
    }
    return nil
  }

  public func toRFC1123String() -> String? {
    return NSDate.RFC1123DateFormatter().stringFromDate(self)
  }
}