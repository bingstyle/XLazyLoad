//
//  SourceEditorCommand.swift
//  WXBLazyLoad
//
//  Created by WeiXinbing on 2021/7/23.
//

import Foundation
import XcodeKit

class SourceEditorCommand: NSObject, XCSourceEditorCommand {
    
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        // Implement your command here, invoking the completion handler when done. Pass it nil on success, and an NSError on failure.
        GetterMaker.shared.lazyLoad(invocation)
        completionHandler(nil)
    }
    
}
