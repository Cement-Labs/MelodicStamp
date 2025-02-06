//
//  CGFloat+Extensions.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/23.
//

import AppKit

extension CGFloat {
    static func preferredPointSize(forTextStyle textStyle: NSFont.TextStyle) -> CGFloat {
        NSFont.preferredFont(forTextStyle: textStyle).pointSize
    }
}
