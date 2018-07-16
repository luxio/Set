//
//  Card.swift
//  Set
//
//  Created by Stéphane Lux on 04.02.2018.
//  Copyright © 2018 LUXio IT-Solutions. All rights reserved.
//

import Foundation

struct Card: Hashable {
    static let numberOfAttributes = 4
    
    var hashValue: Int { return identifier   }
    
    static func ==(lhs: Card, rhs: Card) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
    private var identifier: Int
    private static var identifierFactory = 0
    
    let attributes : [CardAttribute]

    private static func getUnitqueIdentifier() -> Int {
        identifierFactory += 1
        return identifierFactory
    }
    
    init(attributes: [CardAttribute]) {
        identifier = Card.getUnitqueIdentifier()
        self.attributes = attributes
    }
}

enum CardAttribute: Equatable {
    case variant1
    case variant2
    case variant3
    
    static var all:[CardAttribute] {
        return [.variant1, .variant2, .variant3]
    }
}
