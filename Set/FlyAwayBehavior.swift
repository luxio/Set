//
//  FlyAwayBehavior.swift
//  Set
//
//  Created by Stéphane Lux on 12.05.2018.
//  Copyright © 2018 LUXio IT-Solutions. All rights reserved.
//
//
//  CardBehavior.swift
//  PlayingCard
//
//  Created by CS193p Instructor on 10/18/17.
//  Copyright © 2017 CS193p Instructor. All rights reserved.
//

import UIKit

class FlyAwayBehavior: UIDynamicBehavior
{
    lazy var collisionBehavior: UICollisionBehavior = {
        let behavior = UICollisionBehavior()
        behavior.translatesReferenceBoundsIntoBoundary = true
        return behavior
    }()
    
    lazy var itemBehavior: UIDynamicItemBehavior = {
        let behavior = UIDynamicItemBehavior()
        behavior.allowsRotation = true
        behavior.elasticity = 1.0
        behavior.resistance = 0
        return behavior
    }()
    
    private var delayTimer = 0.0
    
    private func snap(_ item: UIDynamicItem, snapTo: CGPoint) {
        let snap = UISnapBehavior(item: item, snapTo: snapTo)
        snap.damping = 1.0
        addChildBehavior(snap)
    }
    
    private func push(_ item: UIDynamicItem) {
        let push = UIPushBehavior(items: [item], mode: .instantaneous)
        if let referenceBounds = dynamicAnimator?.referenceView?.bounds {
            let center = CGPoint(x: referenceBounds.midX, y: referenceBounds.midY)
            switch (item.center.x, item.center.y) {
            case let (x, y) where x < center.x && y < center.y:
                push.angle = (CGFloat.pi/2).arc4random
            case let (x, y) where x > center.x && y < center.y:
                push.angle = CGFloat.pi-(CGFloat.pi/2).arc4random
            case let (x, y) where x < center.x && y > center.y:
                push.angle = (-CGFloat.pi/2).arc4random
            case let (x, y) where x > center.x && y > center.y:
                push.angle = CGFloat.pi+(CGFloat.pi/2).arc4random
            default:
                push.angle = (CGFloat.pi*2).arc4random
            }
        }
        push.magnitude = CGFloat(10.0) + CGFloat(2.0).arc4random
        push.action = { [unowned push, weak self] in
            self?.removeChildBehavior(push)
        }
        addChildBehavior(push)
    }
    
    func addItem(_ item: UIDynamicItem, snapTo : CGPoint) {
        collisionBehavior.addItem(item)
        itemBehavior.addItem(item)
        push(item)
        
        Timer.scheduledTimer(withTimeInterval: SetMainViewController.AnimationSettings.flyOutDuration, repeats: false) {_ in
            self.collisionBehavior.removeItem(item)
            self.snap(item, snapTo: snapTo)
        }
    }
    
    func removeItem(_ item: UIDynamicItem) {
        collisionBehavior.removeItem(item)
        itemBehavior.removeItem(item)
    }
    
    override init() {
        super.init()
        addChildBehavior(collisionBehavior)
        addChildBehavior(itemBehavior)
    }
    
    convenience init(in animator: UIDynamicAnimator) {
        self.init()
        animator.addBehavior(self)
    }
}
