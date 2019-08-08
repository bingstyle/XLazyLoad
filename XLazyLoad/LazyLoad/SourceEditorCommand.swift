//
//  SourceEditorCommand.swift
//  LazyLoad
//
//  Created by WeiXinbing on 2019/8/8.
//  Copyright © 2019 wxb. All rights reserved.
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
