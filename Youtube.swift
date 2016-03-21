//
//  Youtube.swift
//  youtube-parser
//
//  Created by Toygar Dündaralp on 7/5/15.
//  Copyright (c) 2015 Toygar Dündaralp. All rights reserved.
//

import UIKit

public extension NSURL {
  /**
  Parses a query string of an NSURL

  @return key value dictionary with each parameter as an array
  */
  func dictionaryForQueryString() -> [String: AnyObject]? {
    return self.query?.dictionaryFromQueryStringComponents()
  }
}

public extension String {
  /**
  Convenient method for decoding a html encoded string
  */
  func stringByDecodingURLFormat() -> String {
    let result = self.stringByReplacingOccurrencesOfString("+", withString:" ")
    return  result.stringByRemovingPercentEncoding!
  }

  /**
  Parses a query string

  @return key value dictionary with each parameter as an array
  */
  func dictionaryFromQueryStringComponents() -> [String: AnyObject] {
    var parameters = [String: AnyObject]()
    for keyValue in componentsSeparatedByString("&") {
      let keyValueArray = keyValue.componentsSeparatedByString("=")
      if keyValueArray.count < 2 {
        continue
      }
      let key = keyValueArray[0].stringByDecodingURLFormat()
      let value = keyValueArray[1].stringByDecodingURLFormat()
      parameters[key] = value
    }
    return parameters
  }
}

public class Youtube: NSObject {
    static let infoURL = "http://www.youtube.com/get_video_info?video_id="
    static var userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/537.4 (KHTML, like Gecko) Chrome/22.0.1229.79 Safari/537.4"
    
  /**
  Method for retrieving the youtube ID from a youtube URL

  @param youtubeURL the the complete youtube video url, either youtu.be or youtube.com
  @return string with desired youtube id
  */
  public static func youtubeIDFromYoutubeURL(youtubeURL: NSURL) -> String? {
    if let
      youtubeHost = youtubeURL.host,
      youtubePathComponents = youtubeURL.pathComponents as [String]? {
        let youtubeAbsoluteString = youtubeURL.absoluteString
        if youtubeHost == "youtu.be" {
          return youtubePathComponents[1]
        } else if youtubeAbsoluteString.rangeOfString("www.youtube.com/embed") != nil {
          return youtubePathComponents[2]
        } else if youtubeHost == "youtube.googleapis.com" ||
          youtubeURL.pathComponents!.first! == "www.youtube.com" {
            return youtubePathComponents[2]
        } else if let
          queryString = youtubeURL.dictionaryForQueryString(),
          searchParam = queryString["v"] as? String {
            return searchParam
        }
    }
    return nil
  }
  /**
  Method for retreiving a iOS supported video link

  @param youtubeURL the the complete youtube video url
  @return dictionary with the available formats for the selected video
  
  */
    public static func h264videosWithYoutubeID(youtubeID: String,handler:(([String: AnyObject]?)->())?){
        if youtubeID.characters.count > 0{
            let urlString = String(format: "%@%@", infoURL, youtubeID)
            guard let url = NSURL(string: urlString) else
            {
                handler?(nil)
                return
            }
            let request = NSMutableURLRequest(URL: url)
            request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
            request.HTTPMethod = "GET"
            request.timeoutInterval = 15
            
            let manager = Manager.sharedInstance
            manager.request(request).response(completionHandler: { (_, response, data, error) -> Void in
                if error != nil {
                    handler?(nil)
                    return
                }
                
                guard let responseData = data , responseString = String(data: responseData, encoding: NSUTF8StringEncoding) else{
                    handler?(nil)
                    return
                }
                
                let parts = responseString.dictionaryFromQueryStringComponents()
                if parts.count > 0 {
                    var videoTitle: String = ""
                    var streamImage: String = ""
                    if let title = parts["title"] as? String {
                        videoTitle = title
                    }
                    if let image = parts["iurl"] as? String {
                        streamImage = image
                    }
                    if let fmtStreamMap = parts["url_encoded_fmt_stream_map"] as? String {
                        // Live Stream
                        if let _: AnyObject = parts["live_playback"]{
                            if let hlsvp = parts["hlsvp"] as? String {
                                handler? ([
                                    "url": "\(hlsvp)",
                                    "title": "\(videoTitle)",
                                    "image": "\(streamImage)",
                                    "isStream": true
                                    ])
                            }
                        } else {
                            let fmtStreamMapArray = fmtStreamMap.componentsSeparatedByString(",")
                            if fmtStreamMapArray.count > 0{
                                var videoComponents = [String: AnyObject]()
                                for videoEncodedString in fmtStreamMapArray{
                                    var dict = videoEncodedString.dictionaryFromQueryStringComponents()
                                    
                                    guard let type:String = dict["type"] as? String else{
                                        continue
                                    }
                                    if type.rangeOfString("mp4") != nil {
                                        videoComponents = dict
                                        videoComponents["title"] = videoTitle
                                        videoComponents["isStream"] = false
                                        break
                                    }
                                    print("ad")
                                    
                                }
                                
                                handler?(videoComponents as [String: AnyObject])
                                
                            }else
                            {
                                handler?(nil)
                            }
                        }
                    }else{
                        handler?(nil)
                    }
                }
            })
        }else
        {
            handler?(nil)
        }
    }
  /**
  Block based method for retreiving a iOS supported video link

  @param youtubeURL the the complete youtube video url
  @param completeBlock the block which is called on completion

  */
  public static func h264videosWithYoutubeURL(youtubeURL: NSURL,completion: ((
    videoInfo: [String: AnyObject]?, error: NSError?) -> Void)?) {
        guard let youtubeID = self.youtubeIDFromYoutubeURL(youtubeURL) else{
            completion?(videoInfo: nil, error: NSError(domain: "com.player.youtube.backgroundqueue", code: 1001, userInfo: ["error": "Invalid YouTube URL"]))
            return
        }
        
        self.h264videosWithYoutubeID(youtubeID, handler: { (params:[String: AnyObject]?) -> () in
            completion?(videoInfo: params, error: nil)
            return
        })
    }
  }
