//
//  ApiModel.swift
//  JSONExport
//
//  Created by google on 2019/12/9.
//  Copyright © 2019 Ahmed Ali. All rights reserved.
//

import Cocoa
import HandyJSON

class APIProperty: NSObject, HandyJSON{
    
    
    @objc var name : String?
    @objc var type : String?
    
    @objc required override init() {}
    
    
}

class ApiModel: NSObject, HandyJSON {
    
    @objc var properties : [APIProperty] = []
    @objc var title : String?
    @objc var name : String?
    
    @objc required override init() {}
}
