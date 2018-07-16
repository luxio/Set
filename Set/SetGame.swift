//
//  Set.swift
//  Set
//
//  Created by Stéphane Lux on 04.02.2018.
//  Copyright © 2018 LUXio IT-Solutions. All rights reserved.
//

import Foundation

struct SetGame {
    private(set) var deck = [Card]()
    private(set) var dealedCards = [Card]()
    private(set) var chosenCards = [Card]()
    private(set) var matchedCards = [Card]()
    private(set) var score = 0
    
    mutating func shuffleDealedCards() {
        var shuffledCards = [Card]()
        var index = 0
        for _ in 1..<dealedCards.count {
            index = (dealedCards.count - 1).arc4random  + 1
            shuffledCards.append(dealedCards.remove(at: index))
        }
        // add last remaining card
        shuffledCards.append(dealedCards.remove(at: 0))
        dealedCards = shuffledCards
    }
    
    mutating func chooseCard(_ card: Card){
        if chosenCards.count == 3 {
            chosenCards = [Card]()
        }
        if dealedCards.contains(card)  {
            if chosenCards.contains(card) {
                chosenCards.remove(at: chosenCards.index(of: card)!)
                score -= 1
            } else {
                chosenCards.append(card)
            }
        }
        if chosenCards.count == 3 {
            if isSet {
                matchedCards += chosenCards
                score += 3
                dealedCards = dealedCards.filter ({!chosenCards.contains($0)})
                dealCards(number: 3)
                
            } else {
                score -= 5
            }
        }
    }
    
    mutating func dealCards(number: Int) {
        if isSet {
            // remove Set
            dealedCards = dealedCards.filter { !chosenCards.contains($0)}
            chosenCards = [Card]()
        }  else {
            // penalty if there is a set
            if dealedCards.count > 0, setInDealedCards.count > 0 {
                score -= 3
            }
        }
        for _ in 1...number {
            if deck.count > 0 {
                dealedCards.append(deck.remove(at: deck.count.arc4random))
            }
        }
    }
    
    func isSet(_ cards:[Card]) -> Bool {
        if cards.count < 3 {return false}
        let (card1, card2, card3) = (cards[0], cards[1], cards[2])
        for cardAttributeIndex in 0..<Card.numberOfAttributes {
            let cardAttributesSet = Set([
                card1.attributes[cardAttributeIndex],
                card2.attributes[cardAttributeIndex],
                card3.attributes[cardAttributeIndex],
                ])
            if cardAttributesSet.count == 2 { return false }
        }
        return true
    }
    
    var isSet : Bool {
        get {
            return isSet(chosenCards)
        }
    }
    
    // find a set within the dealed cards
    var setInDealedCards : [Card] {
        get {
            var setInDealedCards = [Card]()
            var remainingCards = dealedCards
            for card1 in remainingCards {
                setInDealedCards.append(remainingCards.remove(at: remainingCards.index(of: card1)!))
                for card2 in remainingCards {
                    setInDealedCards.append(remainingCards.remove(at: remainingCards.index(of: card2)!))
                    for card3 in remainingCards {
                        setInDealedCards.append(remainingCards.remove(at: remainingCards.index(of: card3)!))
                        if isSet(setInDealedCards) {
                            return setInDealedCards
                        } else {
                            remainingCards.append(setInDealedCards.removeLast())
                        }
                    }
                    remainingCards.append(setInDealedCards.removeLast())
                }
                remainingCards.append(setInDealedCards.removeLast())
                
            }
            
            return setInDealedCards
        }
    }
    
    init() {
        func createDeck(_ attributes: [CardAttribute] = [CardAttribute]())  {
            for variant in CardAttribute.all {
                if attributes.count < Card.numberOfAttributes - 1 {
                    createDeck(attributes + [variant])
                } else {
                    deck.append(Card(attributes: attributes + [variant]))
                }
            }
        }
        createDeck()
    }
}

extension Int {
    var arc4random: Int {
        if self > 0 {
            return Int(arc4random_uniform(UInt32(self)))
        } else if self < 0 {
            return -Int(arc4random_uniform(UInt32(abs(self))))
        } else {
            return 0
        }
    }
}
