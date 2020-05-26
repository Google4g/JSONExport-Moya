//
//  FilePreviewCell.swift
//  JSONExport
//
//  Created by Ahmed on 11/10/14.
//  Copyright (c) 2014 Ahmed Ali. All rights reserved.
//

import Cocoa

class FilePreviewCell: NSTableCellView, NSTextViewDelegate {

    
    @IBOutlet var classNameLabel: NSTextFieldCell!
    @IBOutlet var constructors: NSButton!
    @IBOutlet var utilities: NSButton!
    @IBOutlet var textView: NSTextView!
    @IBOutlet var scrollView: NSScrollView!
    
    var modelArr : [ApiModel] = []
    var isAPI = true
    var file: FileRepresenter!{
        didSet{
            if file != nil{
                DispatchQueue.main.async {
                    var fileName = self.file.className
                    fileName += "."
                    if self.file is HeaderFileRepresenter{
                        fileName += self.file.lang.headerFileData.headerFileExtension
                    }else{
                        fileName += self.file.lang.fileExtension
                    }
                    self.classNameLabel.stringValue = fileName
                    if(self.textView != nil){
                        self.textView.string = self.file.toString()
                    }
                    
                    if self.file.includeConstructors{
                        self.constructors.state = NSControl.StateValue.on
                    }else{
                        self.constructors.state = NSControl.StateValue.off
                    }
                    if self.file.includeUtilities{
                        self.utilities.state = NSControl.StateValue.on
                    }else{
                        self.utilities.state = NSControl.StateValue.off
                    }
                }
            }else{
                classNameLabel.stringValue = ""
            }
        }
    }
    
    var moyas: [MoyaObject]!{
        didSet{
            if moyas.count > 0{
                DispatchQueue.main.async {
                    if self.isAPI{
                        self.classNameLabel.stringValue = "MWAPI.swift"
                        if(self.textView != nil){
                            self.textView.string = self.toString()
                        }
                    }else{
                        self.classNameLabel.stringValue = "MWIMPAPI.swift"
                        if(self.textView != nil){
                            self.textView.string = self.impToString()
                        }
                    }
                    
                }
            }else{
                classNameLabel.stringValue = ""
            }
        }
    }
    func impToString() -> String{
        var fileContent = ""
        fileContent +=  "\n"
        fileContent += "import Foundation\nimport RxSwift\nimport RxCocoa\n"
        
        // protocol
        fileContent += "\n"
        fileContent += "protocol MWIMPAPIProtocol {\n"
        for moya in self.moyas {
            fileContent += "\tfunc \(moya.operationId ?? "")\(toString(moya: moya)) -> Observable<Any>\n"
        }
        fileContent += "}\n"
    
        return fileContent
    }
    
    func toString() -> String {
        var fileContent = ""
        fileContent +=  "\n"
        fileContent += "import Foundation\nimport Moya\nimport HandyJSON\n"
        
        
        fileContent += "\n"
        fileContent += "enum API {\n"
        for moya in self.moyas {
            fileContent += "\t// \(moya.summary ?? "")\n"
            fileContent += "\tcase \(moya.operationId ?? "")\(toString(moya: moya))\n"
        }
        fileContent += "\n}"
        
        // sampleData
        fileContent += "\n\n"
        fileContent += "extension API : TargetType {\n"
        fileContent += "\n\tvar sampleData: Data {\n\t\treturn \"\".utf8Encoded\n\t}\n\n"
        
         // task
        fileContent += "\tvar task: Task {\n\t\tif let parameters = parameters {\n\t\t\tif self.method == .get {\n\t\t\t\treturn .requestParameters(parameters: parameters, encoding: URLEncoding.default)\n\t\t\t}else{\n\t\t\t\treturn .requestParameters(parameters: parameters, encoding: JSONEncoding.default)\n\t\t\t}\n\t\t}\n\t\treturn .requestPlain\n\t}\n"
        
        // headers
        fileContent += "\n\n"
        fileContent += "\tvar headers: [String : String]? {\n\t\treturn [\n\t\t\t\"Content-type\": \"application/json\",\n\t\t\t\"token\": Defaults[.tokenKey]]\n\t}\n"
        
        // baseURL
        fileContent += "\n\n"
        fileContent += "\tvar baseURL: URL {\n\t\treturn URL(string: \"\")!\n\t}\n"
        
        // path
        fileContent += "\n\n"
        fileContent += "\tvar path: String {\n\t\tswitch self {\n"
        for moya in self.moyas {
            if moya.isInPath {
                for parameter in moya.parameters ?? [] {
                    if parameter.methods == "path" {
                        // 对path参数进行转化
                        fileContent += "\t\tcase .\(moya.operationId ?? "")(let \(parameter.name ?? "")):\n"
                        fileContent += "\t\t\treturn \"\(moya.path!.replacingOccurrences(of: "{\(parameter.name ?? "")}", with: "\\(\(parameter.name ?? ""))"))\"\n"
                    }
                }
            }else{
                fileContent += "\t\tcase .\(moya.operationId ?? ""):\n"
                fileContent += "\t\t\treturn \"\(moya.path ?? "")\"\n"
            }
            
        }
        fileContent += "\t\tdefault:\n\t\t\treturn \"\"\n\t\t}\n"
        fileContent += "\t}\n"
        
        // parameters
        fileContent += "\n\n"
        fileContent += "\tvar parameters: [String: Any]? {\n\t\tvar params: [String: Any] = [:]\n\t\tswitch self {\n"
        for moya in moyas {
            if moya.isInPath {
                if moya.parameters?.count ?? 0 > 2 { // 除token 跟 path 外还有其他类型的参数
                    fileContent += parametersToString(moya: moya)
                }
            }else{
                if moya.parameters?.count ?? 0 > 1 { // 除token 跟 path 外还有其他类型的参数
                    fileContent += parametersToString(moya: moya)
                }
            }
        }
        fileContent += "\t\tdefault:\n\t\t\tbreak\n\t\t}\n\t\treturn params\n"
        fileContent += "\t}\n"
        
        fileContent += "\n\n"
        fileContent += methodToString()
        
        fileContent += "}\n"
        
        
        return fileContent
    }
    // enum 参数
    func toString(moya: MoyaObject) -> String {
        var fileContent = ""
        for parameter in moya.parameters ?? [] {
            var typeStr = "String"
            if parameter.type == "integer"{
                typeStr = "Int"
            }else if parameter.type == "array"{
                typeStr = "Array"
            }
            if parameter.schema?.name?.count ?? 0 > 0 {
                for model in self.modelArr {
                    if model.title == parameter.schema?.name! {
                        for property in model.properties {
                            var propertyStr = "String"
                            if property.type == "integer"{
                                propertyStr = "Int"
                            }else if property.type == "array"{
                                propertyStr = "Array"
                            }else if property.type == "number"{
                                propertyStr = "Double"
                            }
                            
                            fileContent += "\(property.name ?? ""): \(propertyStr), "
                        }
                    }
                }
            }else{
                if parameter.name != "token" {
                    fileContent += "\(parameter.name ?? ""): \(typeStr), "
                }
            }
        }
        if fileContent.count >= 2 {
            fileContent.removeLast(2)
            if isAPI { // enum
                fileContent.insert("(", at: fileContent.startIndex)
                fileContent.insert(")", at: fileContent.endIndex)
            }
        }
        if !isAPI { // 接口
            fileContent.insert("(", at: fileContent.startIndex)
            fileContent.insert(")", at: fileContent.endIndex)
        }
        return fileContent
    }
    // 参数格式化
    func parametersToString(moya: MoyaObject) -> String {
        var fileContent = "\t\tcase .\(moya.operationId ?? "")("
        var shouldRemove = false
        for parameter in moya.parameters ?? [] {
            if parameter.methods != "header" && parameter.methods != "path"{
                if parameter.schema?.name?.count ?? 0 > 0 { // 如果指定了模型得进行转化
                    for model in self.modelArr {
                        if model.title == parameter.schema?.name! {
                            for property in model.properties {
                                fileContent += "let \(property.name ?? ""), "
                            }
                        }
                    }
                }else{
                   fileContent += "let \(parameter.name ?? ""), "
                   
                }
                shouldRemove = true
            }
            
        }
        if shouldRemove {
            fileContent.removeLast(2)
            fileContent += "):\n"
            for parameter in moya.parameters ?? []{
                if parameter.methods != "header" && parameter.methods != "path"{
                    
                    if parameter.schema?.name?.count ?? 0 > 0 { // 如果指定了模型得进行转化
                        for model in self.modelArr {
                            if model.title == parameter.schema?.name! {
                                for property in model.properties {
                                    fileContent += "\t\t\tparams[\"\(property.name ?? "")\"] = \(property.name ?? "")\n"
                                }
                            }
                        }
                    }else{
                       fileContent += "\t\t\tparams[\"\(parameter.name ?? "")\"] = \(parameter.name ?? "")\n"
                       
                    }
                }
            }
        }
        return fileContent
    }
    
    func methodToString() -> String{
        var getMethods = [String]()
        var putMethods = [String]()
        var deleteMethods = [String]()
        
        for moya in moyas {
            if moya.method == "get" {
                getMethods.append(".\(moya.operationId ?? "")")
            }else if moya.method == "put"{
                putMethods.append(".\(moya.operationId ?? "")")
            }else if moya.method == "delete"{
                deleteMethods.append(".\(moya.operationId ?? "")")
            }
        }
        
        var fileContent = ""
        fileContent += "\tvar method: Moya.Method {\n\t\tswitch self {\n"
        
        var getContent = ""
        for obj in getMethods {
            getContent += "\(obj), "
        }
        if getMethods.count > 0 {
            getContent.insert(contentsOf: "\t\tcase ", at: getContent.startIndex)
            getContent.removeLast(2)
            getContent += ":\n\t\t\treturn .get\n"
        }
        var putContent = ""
        for obj in putMethods {
            putContent += "\(obj), "
        }
        if putMethods.count > 0 {
            putContent.insert(contentsOf: "\t\tcase ", at: putContent.startIndex)
            putContent.removeLast(2)
            putContent += ":\n\t\t\treturn .put\n"
        }
        
        var deleteContent = ""
        for obj in deleteMethods {
            deleteContent += "\(obj), "
        }
        if deleteMethods.count > 0 {
            deleteContent.insert(contentsOf: "\t\tcase ", at: deleteContent.startIndex)
            deleteContent.removeLast(2)
            deleteContent += ":\n\t\t\treturn .delete\n"
        }
        fileContent += getContent
        fileContent += putContent
        fileContent += deleteContent
        fileContent += "\t\tdefault:\n\t\t\treturn .post\n\t\t}\n\t}\n"
        return fileContent
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if textView != nil{
            textView.delegate = self
            DispatchQueue.main.async {
                self.setupNumberedTextView()
            }
        }
    }
    
    func setupNumberedTextView()
    {
        let lineNumberView = NoodleLineNumberView(scrollView: scrollView)
        scrollView.hasHorizontalRuler = false
        scrollView.hasVerticalRuler = true
        scrollView.verticalRulerView = lineNumberView
        scrollView.rulersVisible = true
        textView.font = NSFont.userFixedPitchFont(ofSize: NSFont.smallSystemFontSize)
        
    }
    
    @IBAction func toggleConstructors(_ sender: NSButtonCell)
    {
        if file != nil{
            file.includeConstructors = (sender.state == NSControl.StateValue.off)
            textView.string = file.toString()
            
        }
    }
    
    @IBAction func toggleUtilityMethods(_ sender: NSButtonCell)
    {
        if file != nil{
            file.includeUtilities = (sender.state == NSControl.StateValue.on)
            textView.string = file.toString()
        }
    }
    
    func textDidChange(_ notification: Notification) {
		file.fileContent = textView.string
    }
}
