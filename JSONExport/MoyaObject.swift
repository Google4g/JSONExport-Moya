//
//  MoyaObject.swift
//  JSONExport
//
//  Created by google on 2019/12/9.
//  Copyright © 2019 Ahmed Ali. All rights reserved.
//

import Cocoa
import HandyJSON

class Schema: NSObject, HandyJSON {

    @objc var name : String?{
        if let name = _name?.split(separator: "/").map(String.init) {
            return name.last
        }
        return _name
    }
    @objc var _name : String?
    @objc required override init() {}
    
    func mapping(mapper: HelpingMapper) {
        mapper <<<
            self._name <-- "$ref"
    }
}

class Parameter: NSObject, HandyJSON{
    
    @objc var des : String?
    @objc var name : String?
    var required : Bool?
    @objc var type : String?
    @objc var schema : Schema?
    @objc var methods : String?
   
    
    @objc required override init() {}
    func mapping(mapper: HelpingMapper) {
        mapper <<<
            self.des <-- "description"
        mapper <<<
            self.methods <-- "in"
    }
    
    
}

class MoyaObject: NSObject, HandyJSON {
    
    @objc var operationId : String?
    @objc var parameters : [Parameter]?
    @objc var summary : String?
    @objc var method : String?
    @objc var path : String?
    var isInPath : Bool{
        for parameter in parameters ?? [] {
            if parameter.methods == "path"{
                return true
            }
        }
        return false
    }
    
    @objc required override init() {}
    
   
}
