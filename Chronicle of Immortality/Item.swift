//
//  Item.swift
//  Chronicle of Immortality
//
//  Created by wangqiyang on 2026/5/21.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
