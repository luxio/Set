//
//  ViewController.swift
//  Set
//
//  Created by Stéphane Lux on 04.02.2018.
//  Copyright © 2018 LUXio IT-Solutions. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet var cardButtons: [UIButton]!
    @IBOutlet weak var dealButton: UIButton!
    @IBOutlet weak var scoreLabel: UILabel!
    
    var game = SetGame()
    var showCheatSet = false
    
    lazy var cardAtButtonIndex : [Card?] = Array(repeatElement(nil, count: cardButtons.count))
    private var score = 0  {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startGame()
    }
    
    @IBAction private func startGame() {
        game = SetGame()
        self.dealCards(12)
    }
    
    @IBAction func cheatButtonPressed(_ sender: Any) {
        showCheatSet = true
        updateViewFromModel()
    }
    
    
    @IBAction func DealButtonPressed(_ sender: Any) {
        dealCards(3)
    }
    
    func dealCards(_ number: Int) {
        game.dealCards(number: number)
        updateViewFromModel()
    }
    
    @IBAction private func touchCard(_ sender: UIButton) {
        //        if let card = cardOfButton1[sender] as? Card {
        if let card = cardAtButtonIndex[cardButtons.index(where: {$0 == sender})!] {
            game.chooseCard(card)
            updateViewFromModel()
        }
    }
    
    private func updateViewFromModel() {
        // check for cards to be removed
        var cardsToBeRemoved = cardAtButtonIndex.filter {$0 != nil}.filter { !game.dealedCards.contains($0!)}
        
        // check for new cards
        for card in game.dealedCards.filter({ card in !cardAtButtonIndex.contains(where: {card == $0})}) {
            // check for cards to be replaced
            if let cardToRemoved = cardsToBeRemoved.popLast() {
                cardAtButtonIndex[cardAtButtonIndex.index(where: {$0 == cardToRemoved})!] = card
            } else {
                if let index = cardAtButtonIndex.index(where: {$0 == nil}) {
                    cardAtButtonIndex[index] = card
                }
            }
        }
        
        // remove cards
        cardsToBeRemoved.forEach { card in
            cardAtButtonIndex[cardAtButtonIndex.index(where: {$0 == card})!] = nil
        }
        
        // update card buttons
        for (buttonIndex, button) in cardButtons.enumerated() {
            if let card = cardAtButtonIndex[buttonIndex] {
                // show card
                button.titleLabel?.numberOfLines = 0
                button.setAttributedTitle(symbol(for: card), for: .normal)
                button.layer.borderColor = game.chosenCards.contains(card) ?
                    (game.matchedCards.contains(card) ? #colorLiteral(red: 0, green: 1, blue: 0, alpha: 1):#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) ) : #colorLiteral(red: 0.2039215686, green: 0.2039215686, blue: 0.2039215686, alpha: 0)
                button.layer.cornerRadius = 8.0
                button.layer.borderWidth = 2.0
                button.layer.backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
                button.isEnabled = true;
            } else {
                // hide button
                button.layer.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
                button.layer.borderColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
                button.isEnabled = false;
                button.setAttributedTitle(nil, for: .normal)
                button.setTitle(nil, for: .normal)
            }
        }
        
        // check if deal button should be disabled
        dealButton.isEnabled = true;
        if !game.isSet {
            if cardAtButtonIndex.filter({ $0 != nil}).count >= cardButtons.count || game.deck.count <= 1 {
                dealButton.isEnabled = false;
            }
        }
        // update score
        score = game.score
        
        // show cheat
        if showCheatSet {
            for card in game.setInDealedCards {
                cardButtons[cardAtButtonIndex.index(where: {$0 == card})!].layer.borderColor = #colorLiteral(red: 1, green: 0.4791216254, blue: 0, alpha: 1)
            }
            showCheatSet = false
        }
        
    }
    
    private var cardSymbol = [Card:NSAttributedString]()
    
    private func symbol(for card: Card) -> NSAttributedString {
        if cardSymbol[card] == nil {
            let cardString = [String](
                repeating: card.attributes[0].symbol,
                count: card.attributes[1].symbolCount
                ).joined(separator: "\n")
            
            let cardAttribudedString = NSMutableAttributedString(
                string: cardString,
                attributes: [
                    NSAttributedStringKey.font:UIFont.systemFont(ofSize: 18.0),
                    NSAttributedStringKey.foregroundColor: card.attributes[2].color.withAlphaComponent(card.attributes[3].alpha),
                    NSAttributedStringKey.strokeWidth: card.attributes[3].strokeWidth,
                    ]);
            cardSymbol[card] = cardAttribudedString
        }
        return cardSymbol[card]!
    }
}

extension CardAttribute {
    var symbol: String {
        switch self {
        case .variant1: return "▲"
        case .variant2: return "●"
        case .variant3: return "■"
        }
    }
    
    var symbolCount: Int {
        switch self {
        case .variant1: return 1
        case .variant2: return 2
        case .variant3: return 3
        }
    }
    
    var color: UIColor {
        switch self {
        case .variant1: return #colorLiteral(red: 1, green: 0, blue: 0, alpha: 1)
        case .variant2: return #colorLiteral(red: 0, green: 1, blue: 0, alpha: 1)
        case .variant3: return #colorLiteral(red: 0, green: 0, blue: 1, alpha: 1)
        }
    }
    
    var strokeWidth: CGFloat {
        switch self {
        case .variant1: return 5.0
        case .variant2: return 0.0
        case .variant3: return 0.0
        }
    }
    
    var alpha: CGFloat {
        switch self {
        case .variant1: return 1.0
        case .variant2: return 1.0
        case .variant3: return 0.15
        }
    }
}

