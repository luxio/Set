//
//  SetMainViewController.swift
//  Set
//
//  Created by Stéphane Lux on 22.04.2018.
//  Copyright © 2018 LUXio IT-Solutions. All rights reserved.
//

import UIKit

class SetMainViewController: UIViewController, UIDynamicAnimatorDelegate {
    
    @IBOutlet weak var setsCountLabel: UILabel!
    @IBOutlet weak var dealButton: UIButton!
    @IBOutlet weak var deckView: UIView!
    @IBOutlet weak var pileView: UIView!
    
    var grid = Grid(layout: .aspectRatio(SizeRatio.aspectRatio))
    let layer = CAShapeLayer()
    var cardViews = [SetCardView]()
    var cardFromView: [SetCardView : Card] = [:]
    private var score = 0  {
        didSet {
            self.title = "Score: \(score)"
        }
    }
    private var setsCount = 0  {
        didSet {
            setsCountLabel.text = "Sets: \(setsCount)"
        }
    }
    lazy var animator = UIDynamicAnimator(referenceView: cardsView)
    lazy var flyAwayBehavior = FlyAwayBehavior(in: animator)
    
    var deckViewCard = SetCardView()
    var pileViewCard = SetCardView()

    func dynamicAnimatorDidPause(_ animator: UIDynamicAnimator) {
        // rotate and turon over on pile
        let items = animator.items(in: (animator.referenceView?.frame)!)
        items.forEach { item in
            if let item = item as? SetCardView {
                UIView.transition(with: item,
                                  duration: AnimationSettings.rotateOnPileDuration,
                                  options: [],
                                  animations: {
                                    item.transform = item.transform.rotated(by: CGFloat(-90.degreesToRadians))
                                    item.frame = self.view.convert(self.pileView.frame, to: self.cardsView)
                },
                                  completion: { position in
                                    UIView.transition(
                                        with: item,
                                        duration: AnimationSettings.flipDuration,
                                        options: [.transitionFlipFromTop],
                                        animations: {
                                            item.isFaceUp = false},
                                        completion: { position in
                                            self.setsCountLabel.isHidden = false
                                            item.removeFromSuperview()
                                            self.pileViewCard.isHidden = false
                                    })
                })
            }
        }
    }
    
    @IBAction func cheatButtonPressed(_ sender: Any) {
        showCheatSet = true
        updateViewFromModel()
    }
    
    @IBAction func DealButtonPressed(_ sender: Any) {
        dealCards(3)
    }
    
    @IBOutlet weak var cardsView: UIView! {
        didSet {
            animator.delegate = self
        }
    }
    
    var game = SetGame()
    var showCheatSet = false
    
    @IBAction private func startGame() {
        game = SetGame()
        cardsView.subviews.forEach { $0.removeFromSuperview() }
        cardViews = [SetCardView]()
        cardFromView = [:]
        setsCountLabel.isHidden = true
        deckViewCard.isHidden = false
        pileViewCard.isHidden = true
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
        
        // creat card stacks
        let cardStacks = [deckViewCard, pileViewCard]
        cardStacks.forEach { cardView in
            cardView.transform = cardView.transform.rotated(by: CGFloat(-90.degreesToRadians))
            cardView.isFaceUp = false
            cardView.isOpaque = false
            //deckView.addSubview(cardView)
            view.addSubview(cardView)
            
            view.sendSubview(toBack: cardView)
            cardView.isHidden = true
        }
    }
    
    @objc private func shuffle(_ sender: UIRotationGestureRecognizer) {
        switch sender.state {
        case .ended:
            //            game.shuffleDealedCards()
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
        if let chosenCard = cardFromView[(sender.view as? SetCardView)!] {
            game.chooseCard(chosenCard)
        }
        updateViewFromModel()
    }
    
    private func updateViewFromModel(){
        // update layout
        grid.frame = cardsView.bounds
        grid.cellCount = cardViews.count
        cardViews.forEach {
            $0.frame = (grid[cardViews.index(of: $0)!]?.relativeOffsetBy(d: SizeRatio.relativeCardOffset))!
        }
        
        var delay : TimeInterval = 0
        
        // check for cards to be removed
        var cardsToBeRemoved = cardFromView.values.filter { game.matchedCards.contains($0)}
        let removedCardsToBeReplaced = (cardsToBeRemoved.count > 0) &&
            (cardViews.count == game.dealedCards.count) && (game.deck.count > 0)
        
        // remove cards
        for (_, card) in cardsToBeRemoved.enumerated() {
            if let cardView = (cardFromView.filter { $0.value == card}).first?.key {
                cardView.borderColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
                self.flyAwayToDiscardpile(cardView, delay: 0)
                
                if (!removedCardsToBeReplaced) {
                    cardFromView.removeValue(forKey: cardView)
                    cardViews.remove(at: self.cardViews.index(of: cardView)!)
                }
            }
        }

        delay = cardsToBeRemoved.count > 0 ? SetMainViewController.AnimationSettings.flyOutDuration : 0
        
        // update layout
        let oldDimensions = grid.dimensions
        grid.cellCount = game.dealedCards.count
        grid.frame = cardsView.bounds
        let dimensionsChanged = !((oldDimensions.columnCount == grid.dimensions.columnCount) && (oldDimensions.rowCount == grid.dimensions.rowCount))
        
        // rearange cards
        var cardsRearranged = false
        if (dimensionsChanged) {
            for (index, cardView) in cardViews.enumerated() {
                if (true) {
                    cardsRearranged = true
                    UIViewPropertyAnimator.runningPropertyAnimator(
                        withDuration: SetMainViewController.AnimationSettings.rearrangeDuration,
                        delay: delay,
                        options: [],
                        animations: {
                            cardView.frame = self.grid[index]!.relativeOffsetBy(d: SizeRatio.relativeCardOffset)
                    })
                }
            }
        }
        if cardsRearranged { delay += SetMainViewController.AnimationSettings.rearrangeDuration}
        
        // add new cards
        for card in game.dealedCards.filter({ !cardFromView.values.contains($0)}) {
            let setCardView = createCardViewFor(card: card, withFrame: CGRect(x: 0, y: 0, width: (grid[0]?.width)!, height: (grid[0]?.height)!))
            
            if (cardsToBeRemoved.count > 0) {
                // increse set count
                // replace card
                let cardToBeReplaced = cardsToBeRemoved.remove(at: 0)
                let viewOfReplacedCard = (cardFromView.filter { $0.value == cardToBeReplaced}).first!.key
                let indexOfReplacedCard = cardViews.index(of: viewOfReplacedCard)!
                cardViews[indexOfReplacedCard] = setCardView
                cardFromView.removeValue(forKey: viewOfReplacedCard)
                setCardView.frame = grid[indexOfReplacedCard]!.relativeOffsetBy(d: SizeRatio.relativeCardOffset)
            } else {
                cardViews.append(setCardView)
                setCardView.frame = grid[self.cardViews.count - 1]!.relativeOffsetBy(d: SizeRatio.relativeCardOffset)
            }
            cardFromView[setCardView] = card
            setCardView.isOpaque = false
            setCardView.isFaceUp = false
            setCardView.alpha = 0
            cardsView.addSubview(setCardView)
            cardsView.sendSubview(toBack: setCardView)
            let endFrame = setCardView.frame
            setCardView.transform = setCardView.transform.rotated(by: CGFloat(-90.degreesToRadians))
            setCardView.frame = view.convert(deckView.frame, to: cardsView)
            setCardView.alpha = 1
            
            UIViewPropertyAnimator.runningPropertyAnimator(
                withDuration: SetMainViewController.AnimationSettings.dealDuration,
                delay: delay,
                options: [],
                animations: {
                    setCardView.alpha = 1
                    setCardView.transform = setCardView.transform.rotated(by: CGFloat(90.degreesToRadians))
                    setCardView.frame = endFrame
            },
                completion: { postion in
                    self.flipCard(setCardView)
            }
            )
            
            delay += AnimationSettings.dealDelayDuration
        }
        
        // check if deal button should be disabled
        dealButton.isEnabled = true
        deckViewCard.isHidden = false
        if !game.isSet {
            if game.deck.count <= 1 {
                dealButton.isEnabled = false
                deckViewCard.isHidden = true
            }
        }
        
        // update score
        score = game.score
        
        // update sets counter
        setsCount =  game.matchedCards.count / 3
        
        // mark selected cards
        cardViews.forEach {
            let card = cardFromView[$0]
            $0.borderColor = game.chosenCards.contains(card!) ? #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)  : #colorLiteral(red: 0.2039215686, green: 0.2039215686, blue: 0.2039215686, alpha: 0)
        }
        
        // show cheat
        if showCheatSet {
            game.setInDealedCards.forEach {card in
                cardFromView.first(where: { $1 == card})?.key.borderColor = #colorLiteral(red: 1, green: 0.4791216254, blue: 0, alpha: 1)
            }
            showCheatSet = false
        }
        
        // update postion of piles
        deckViewCard.frame = deckView.frame
        pileViewCard.frame = pileView.frame
    }
    
    private func flyAwayToDiscardpile(_ cardView: SetCardView, delay: TimeInterval) {
        // move top top
        cardsView.bringSubview(toFront: cardView)
        // grow
        UIViewPropertyAnimator.runningPropertyAnimator(
            withDuration: AnimationSettings.matchAnimationScaleDuration,
            delay: 0,
            options: [],
            animations: {
                cardView.transform = CGAffineTransform.identity.scaledBy(
                    x: AnimationSettings.matchAnimationScaleFactor,
                    y: AnimationSettings.matchAnimationScaleFactor)
        },
            completion: { position in
                cardView.borderColor = #colorLiteral(red: 0.2039215686, green: 0.2039215686, blue: 0.2039215686, alpha: 0)
                self.flyAwayBehavior.addItem(cardView, snapTo: self.view.convert(self.pileView.center, to: self.cardsView))
        })
    }
    
    private func flipCard(_ cardView: SetCardView) {
        UIView.transition(
            with: cardView,
            duration: AnimationSettings.flipDuration,
            options: [.transitionFlipFromLeft],
            animations: {
                cardView.isFaceUp = !cardView.isFaceUp
        })
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateViewFromModel()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
    
    func frameWithOffset(frame: CGRect) {
        self.frame = frame.relativeOffsetBy(d: SetMainViewController.SizeRatio.relativeCardOffset)
    }
    
}

extension SetMainViewController {
    struct SizeRatio {
        static let aspectRatio : CGFloat = 5/8
        static let relativeCardOffset : CGFloat  = 0.05
    }
    
    struct AnimationSettings {
        static let flyOutDuration : TimeInterval = 2.0
        static let rearrangeDuration : TimeInterval = 1.0
        static let dealDuration : TimeInterval = 0.5
        static let dealDelayDuration: TimeInterval = 0.3
        static let matchAnimationScaleFactor: CGFloat = 1.2
        static let matchAnimationScaleDuration: TimeInterval = 0.5
        static let rotateOnPileDuration: TimeInterval = 0.9
        static let flyAwayAnimationDelayDuration : TimeInterval = 0.5
        static let flipDuration: TimeInterval = 0.5
        static let flyAwayDuration: TimeInterval = 1.0
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

extension FloatingPoint {
    var degreesToRadians: Self { return self * .pi / 180 }
    var radiansToDegrees: Self { return self * 180 / .pi }
}

extension UIView{
    func rotate() {
        let rotation : CABasicAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue = NSNumber(value: Double.pi * 2)
        rotation.duration = 1
        rotation.isCumulative = true
        self.layer.add(rotation, forKey: "rotationAnimation")
    }
}

extension CGFloat {
    var arc4random: CGFloat {
        return self * (CGFloat(arc4random_uniform(UInt32.max))/CGFloat(UInt32.max))
    }
}
