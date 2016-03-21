//
//  Model.swift
//  youtubeExample
//
//  Created by dungvh on 9/24/15.
//  Copyright © 2015 dungvh. All rights reserved.
//

import Foundation

class youTubeItem: Mappable {
    var videoId:String?
    var title:String?
    var publishedAt:String?
    var thumbnails:String?
    init(){
        
    }
    
    required init?(_ map: Map) {
        
    }
    
    func mapping(map: Map) {
        videoId <- map["id.videoId"]
        title <- map["snippet.title"]
        thumbnails <- map["snippet.thumbnails.medium.url"]
        publishedAt <- map["snippet.publishedAt"]
    }
}

class youTubeList: Mappable {
    var nextPageToken:String?
    var items:[youTubeItem]?
    init(){
        
    }
    
    required init?(_ map: Map) {
        
    }
    
    func mapping(map: Map) {
        nextPageToken <- map["nextPageToken"]
        items <- map["items"]
    }
}