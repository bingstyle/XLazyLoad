//
//  GetterMaker.swift
//  WXBLazyLoad
//
//  Created by WeiXinbing on 2021/7/23.
//

import XcodeKit

enum Language: String {
    case swift, java, cpp, objc, objcHeader
}

fileprivate let languageUTIs: [CFString: Language] = [
    kUTTypeSwiftSource: .swift,
    kUTTypeObjectiveCSource: .objc,
    kUTTypeCHeader: .objc,
    kUTTypeJavaSource: .java,
    kUTTypeCPlusPlusSource: .cpp,
    kUTTypeObjectiveCPlusPlusSource: .objc,
    "com.apple.dt.playground" as CFString: .swift
]

class GetterMaker: NSObject {
    
    // 单例对象
    static let shared = GetterMaker()
    // 类名正则
    private let classNameRegex = try! NSRegularExpression(pattern: #"(?<=\))\b\w*\b(?=\<)|(?<=\)).*\b\w*\b(?=\*)"#, options: NSRegularExpression.Options.allowCommentsAndWhitespace)
    // 属性名正则
    private let propertyNameRegex = try! NSRegularExpression(pattern: #"(?<=\*)\b\w*\b(?=\;)"#, options: NSRegularExpression.Options.allowCommentsAndWhitespace)
    
    
    /// 生成懒加载代码
    ///
    /// - Parameter invocation: 调用信息
    func lazyLoad (_ invocation: XCSourceEditorCommandInvocation) {
        guard let language = languageFor(contentUTI: invocation.buffer.contentUTI as CFString) else { return }
        // OC懒加载
        if language == Language.objc {
            let selection = getFirstSelection(invocation.buffer) ?? XCSourceTextRange()
            let lines = getSelectLinesWith(selection, lines: invocation.buffer.lines as! [String])
            var lazyLoadStrings = ""
            for line in lines{
                guard let (className, propertyName) = parseLineString(line) else {
                    continue
                }
                let lazyLoadString = generateLazyLoadString(className: className, propertyName: propertyName)
                lazyLoadStrings.append(lazyLoadString + "\n\n");
            }
            let (lineIndex, hasMark) = findInsertIndex(currentEndLine: selection.end.line, lines: invocation.buffer.lines as! [String])
            
            if hasMark {
                invocation.buffer.lines.insert(lazyLoadStrings, at: lineIndex)
            } else {
                lazyLoadStrings = "#pragma mark - Getters and setters \n\n" + lazyLoadStrings
                invocation.buffer.lines.insert(lazyLoadStrings, at: lineIndex)
            }
            
        }
    }
    
    
}

private extension GetterMaker {
    
    /** 通过UTI获取语言类型 */
    func languageFor(contentUTI: CFString) -> Language? {
        //        print(contentUTI)
        for (uti, language) in languageUTIs {
            if UTTypeConformsTo(contentUTI as CFString, uti) {
                return language
            }
        }
        return nil
    }
    
    /** 获取选择行范围 */
    func getFirstSelection(_ buffer: XCSourceTextBuffer) -> XCSourceTextRange? {
        for range in buffer.selections {
            guard let range = range as? XCSourceTextRange else {
                continue
            }
            return range
        }
        return nil
    }
    
    /** 获取选择行内容 */
    func getSelectLinesWith(_ selection:XCSourceTextRange,lines: [String]) -> [String] {
        var result = [String]()
        for i in selection.start.line ... selection.end.line {
            result.append(lines[i])
        }
        return result;
    }
    
    /** 生成懒加载内容 */
    func generateLazyLoadString(className: String, propertyName: String) -> String {
        
        let otherTempString = #"""
                        - (ClassName *)propertyName {
                            if (_propertyName == nil) {
                                _propertyName = [ClassName new];
                            }
                            return _propertyName;
                        }
                        """#
        var result = otherTempString.replacingOccurrences(of: "ClassName", with: className)
        result = result.replacingOccurrences(of: "propertyName", with: propertyName)
        return result;
        
    }
    
    /** 从选择内容中获取类名和属性名 */
    func parseLineString(_ lineString: String) -> (className: String, propertyName: String)?{
        
        let lineContent = lineString.replacingOccurrences(of:" ", with:"", options: .literal, range: nil)//去除空格
        
        guard lineContent.hasPrefix("@property") else {
            return nil
        }
        
        var className:String?
        var propertyName:String?
        
        let classNameRes = classNameRegex.matches(in: lineContent, options: .reportCompletion, range: NSRange(location: 0,length: lineContent.count))
        if classNameRes.count != 0 {
            className = (lineContent as NSString).substring(with: classNameRes.first!.range)
        }
        let propertyNameRes = propertyNameRegex.matches(in: lineContent, options: .reportCompletion, range: NSRange(location: 0,length: lineContent.count))
        if propertyNameRes.count != 0 {
            propertyName = (lineContent as NSString).substring(with: propertyNameRes.first!.range)
        }
        guard let classNameResult = className,let propertyNameResult = propertyName else {
            return nil
        }
        //        print("className = " + classNameResult!)
        //        print("propertyName = " + propertyNameResult!)
        return(classNameResult,propertyNameResult)
    }
    
    /** 寻找插入懒加载代码的位置 */
    func findInsertIndex(currentEndLine: Int, lines: [String]) -> (lineIndex: Int, mark: Bool) {
        var flag = false
        for index in currentEndLine ..< lines.count {
            let lineString = lines[index]
            
            if lineString.contains("#pragma mark - Getters and setters"){
                print("index = \(index)")
                let resultIndex = index < lines.count - 1 ? index + 1 : index //插入在mark 下面
                return (resultIndex,true)
            }
            
            if lineString.contains("@end"){
                if flag{
                    return (index,false)
                }else{
                    flag = true
                }
            }
        }
        return (lines.count - 1,false)
    }
}

