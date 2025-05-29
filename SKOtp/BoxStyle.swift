//
//  BoxStyle.swift
//  Pods
//
//  Created by IE Mac 05 on 29/05/25.
//

import SwiftUI

public enum BoxStyle {
    case bordered
    case underline
    case roundedBorder
    case filled
    case circle
    case shadow
    case custom((Bool, Bool) -> AnyView)
}
