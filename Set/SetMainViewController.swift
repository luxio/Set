//
//  SetMainViewController.swift
//  Set
//
//  Created by Stéphane Lux on 22.04.2018.
//  Copyright © 2018 LUXio IT-Solutions. All rights reserved.
//

import UIKit

class SetMainViewController: UIViewController {
    
    @IBOutlet weak var dealButton: UIButton!
    @IBOutlet weak var scoreLabel: UILabel!
    
    var grid = Grid(layout: .aspectRatio(SizeRatio.aspectRatio))
    let layer = CAShapeLayer()
    
    var cardOfView: [SetCardView : Card] = [:]
    
    private var score = 0  {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }

    @IBAction func cheatButtonPressed(_ sender: Any) {
        showCheatSet = true
        updateViewFromModel()
    }
    
    @IBAction func DealButtonPressed(_ sender: Any) {
        dealCards(3)
    }
    
    @IBOutlet weak var cardsView: UIView!
    
    var game = SetGame()
    var showCheatSet = false
    
    @IBAction private func startGame() {
        game = SetGame()
        self.dealCards(12)
    }
    
    @objc private func dealCards(_ number: Int) {
        game.dealCards(number: number)
        updateViewFromModel()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        startGame()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // add swipe gesture
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(deal))
        swipe.direction = .down
        view.addGestureRecognizer(swipe)
        
        // add rotation gesture
        let rotation = UIRotationGestureRecognizer(target: self, action: #selector(shuffle(_:)))
        view.addGestureRecognizer(rotation)
    }
    
    @objc private func shuffle(_ sender: UIRotationGestureRecognizer) {
        switch sender.state {
        case .ended:
            game.shuffleDealedCards()
            updateViewFromModel()
        default:
            break
        }
    }
    
    @objc func deal() {
        dealCards(3)
    }

    
    private func createCardViewFor(card: Card, withFrame frame: CGRect) -> SetCardView {
        let setCardView = SetCardView(frame: frame.relativeOffsetBy(d: SizeRatio.relativeCardOffset))
        setCardView.cardSymbol = card.attributes[0].cardSymbol
        setCardView.symbolColor = card.attributes[1].symbolColor
        setCardView.symbolCount = card.attributes[2].numberOfSymbols
        setCardView.symbolDisplay = card.attributes[3].symbolDisplay
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(touchCard))
        setCardView.addGestureRecognizer(tap)
        
        return setCardView
    }
    
    @objc private func touchCard(_ sender: UITapGestureRecognizer) {
        game.chooseCard(cardOfView[(sender.view as? SetCardView)!]!)
        updateViewFromModel()
    }
    
    private func updateViewFromModel(){
        // delete var cardOfView Dictionary
        cardOfView = [:]
        // delete subviews
        cardsView.subviews.forEach({ $0.removeFromSuperview() })
    
        // set grid
        grid.cellCount = game.dealedCards.count
        grid.frame = cardsView.bounds
        
        for (cardIndex, card) in game.dealedCards.enumerated() {
            let setCardView = createCardViewFor(card: card, withFrame: grid[cardIndex]!)
            setCardView.isOpaque = false
            cardOfView[setCardView] = card
            setCardView.borderColor = game.chosenCards.contains(card) ?
                (game.matchedCards.contains(card) ? #colorLiteral(red: 0, green: 1, blue: 0, alpha: 1):#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) ) : #colorLiteral(red: 0.2039215686, green: 0.2039215686, blue: 0.2039215686, alpha: 0)
            cardsView.addSubview(setCardView)
        }

        // check if deal button should be disabled
        dealButton.isEnabled = true;
        if !game.isSet {
            if game.deck.count <= 1 {
                dealButton.isEnabled = false;
            }
        }
        
        // update score
        score = game.score
        
        // show cheat
        if showCheatSet {
            game.setInDealedCards.forEach {card in
                cardOfView.first(where: { $1 == card})?.key.borderColor = #colorLiteral(red: 1, green: 0.4791216254, blue: 0, alpha: 1)
            }
            showCheatSet = false
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateViewFromModel()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension CardAttribute {
    var cardSymbol: SetCardView.CardSymbol {
        switch self {
        case .variant1: return .rectangle
        case .variant2: return .circle
        case .variant3: return .triangle
        }
    }
    
    var symbolColor: SetCardView.SymbolColor {
        switch self {
        case .variant1: return .color1
        case .variant2: return .color2
        case .variant3: return .color3
        }
    }
    
    var numberOfSymbols : Int {
        switch self {
        case .variant1: return 1
        case .variant2: return 2
        case .variant3: return 3
        }
    }
    
    var symbolDisplay : SetCardView.SymbolDisplay {
        switch self {
        case .variant1: return .filled
        case .variant2: return .stroked
        case .variant3: return .striped
        }
    }
    
    
    
}

extension SetCardView {
    var cardOffsetToCardWidth: CGFloat {
        return bounds.size.height * 0.01
    }
}

extension SetMainViewController {
    struct SizeRatio {
        static let aspectRatio : CGFloat = 5/8
        static let relativeCardOffset : CGFloat  = 0.05
    }
}

extension CGRect {
    func relativeOffsetBy(d: CGFloat) -> CGRect {
        return CGRect(origin: origin.offsetBy(dx: d * width, dy: d * width),
                      size: CGSize(width: width - 2 * (d * width), height: height - 2 * (d * width)))
        
    }
    
    func relativeOffsetBy(dx: CGFloat, dy: CGFloat) -> CGRect {
        return CGRect(origin: origin.offsetBy(dx: dx * width, dy: dy * height),
                      size: CGSize(width: width - 2 * (dx * width), height: height - 2 * (dy * height)))
        
    }
}
