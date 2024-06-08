//
//  Item.swift
//  Todoey
//
//  Created by Raymond Kim on 6/6/24.
//  Copyright © 2024 App Brewery. All rights reserved.
//

import Foundation

class Item: Encodable {
    var title: String = ""
    var done: Bool = false
}
