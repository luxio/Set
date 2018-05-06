//
//  SetCardView.swift
//  Set
//
//  Created by Stéphane Lux on 03.04.2018.
//  Copyright © 2018 LUXio IT-Solutions. All rights reserved.
//

import UIKit

@IBDesignable
class SetCardView: UIView {
    
    var cardSymbol = CardSymbol.triangle
    var symbolColor = SymbolColor.color1
    var symbolDisplay = SymbolDisplay.filled
    var isFaceUp: Bool = false { didSet { setNeedsDisplay(); setNeedsLayout() } }
    
    var borderColor = UIColor.clear { didSet { setNeedsDisplay(); setNeedsLayout() } }
    
    private var shapePath = UIBezierPath()
    private var stripesPath = UIBezierPath()
    
    var border:CAShapeLayer? = nil
    
    @IBInspectable
    var cardSymbolIndex: Int = 0  {
        didSet {
            guard cardSymbolIndex < CardSymbol.allValues.count else { return }
            cardSymbol = CardSymbol.allValues[cardSymbolIndex]
            setNeedsDisplay();
        }
    }
    
    @IBInspectable
    var symbolCount: Int = 1 { didSet { setNeedsDisplay() }}
    
    @IBInspectable
    var symbolColorIndex: Int = 0  {
        didSet {
            guard symbolColorIndex < SymbolColor.allValues.count else { return }
            symbolColor = SymbolColor.allValues[symbolColorIndex]
            setNeedsDisplay();
        }
    }
    
    @IBInspectable
    var symbolDisplayIndex: Int = 0  {
        didSet {
            guard symbolDisplayIndex < SymbolDisplay.allValues.count else { return }
            symbolDisplay = SymbolDisplay.allValues[symbolDisplayIndex]
            setNeedsDisplay();
        }
    }
    
    private func createTriangleAt(origin: CGPoint){
        shapePath.move(to: CGPoint(x: shapeSize/2, y: 0.0).offsetBy(dx: origin.x, dy: origin.y))
        shapePath.addLine(to: CGPoint(x: 0.0, y: shapeSize).offsetBy(dx: origin.x, dy: origin.y))
        shapePath.addLine(to: CGPoint(x: shapeSize, y: shapeSize).offsetBy(dx: origin.x, dy: origin.y))
        shapePath.close()
    }
    
    private func createCircleAt(origin: CGPoint){
        shapePath.move(to: origin.offsetBy(dx: shapeSize, dy: shapeSize/2))
        shapePath.addArc(withCenter: origin.offsetBy(dx: shapeSize/2, dy: shapeSize/2), radius: shapeSize/2, startAngle: 0, endAngle: CGFloat(2*Double.pi), clockwise: true)
    }
    
    private func createRectangelAt(origin: CGPoint) {
        shapePath.move(to: origin)
        shapePath.addLine(to: origin.offsetBy(dx: shapeSize, dy: 0 ))
        shapePath.addLine(to: origin.offsetBy(dx: shapeSize, dy: shapeSize))
        shapePath.addLine(to: origin.offsetBy(dx: 0, dy: shapeSize))
        shapePath.close()
    }
    
    private func createShapePathAt(origin : CGPoint) {
        switch cardSymbol {
        case .triangle:
            createTriangleAt(origin: origin)
        case .circle:
            createCircleAt(origin: origin)
        case .rectangle:
            createRectangelAt(origin: origin)
        }
    }
    
    private func configureShapePath() {
        var shapeOrigin = CGPoint(x: 0, y: 0)
        shapePath = UIBezierPath()
        stripesPath = UIBezierPath()
        
        for _ in 1...symbolCount {
            createShapePathAt(origin: shapeOrigin)
            shapeOrigin = shapeOrigin.offsetBy(dx: 0, dy: shapeSize + shapeOffset)
        }
        
        // move shapepath to center
        shapePath.apply(CGAffineTransform(translationX: (bounds.width - shapePath.bounds.width) / 2, y: (bounds.height - shapePath.bounds.height) / 2))
        
        // set color and fill
        switch symbolDisplay {
        case .filled:
            symbolColor.color.setFill()
            shapePath.fill()
        case .stroked:
            symbolColor.color.setStroke()
            shapePath.lineWidth = strokeWidth
            shapePath.stroke()
        case .striped:
            symbolColor.color.setStroke()
            shapePath.lineWidth = stripeWidth
            shapePath.stroke()
            shapePath.addClip()
            
            // create stripes
            for index in 1...symbolCount {
                stripesPath.append(
                    createStripesPattern(rect:
                        CGRect(origin: shapePath.bounds.origin.offsetBy(dx: 0, dy: CGFloat((index - 1)) * (shapeSize+shapeOffset)),
                                 size: CGSize(width: shapeSize, height: shapeSize))))
            }
            stripesPath.lineWidth = stripeWidth
            stripesPath.stroke()
        }
    }
    
    /**
     Returns a `UIBezierPath` with a stripe pattern
     
     - Parameter origin: starting point
     */
    private func createStripesPattern(rect : CGRect ) -> UIBezierPath
    {
        let baseLine = UIBezierPath()
        let stripePattern = UIBezierPath()
        
        baseLine.move(to: rect.origin)
        baseLine.addLine(to: rect.origin.offsetBy(dx: rect.width, dy: 0))
        
        let move = CGAffineTransform(translationX: 0, y: stripeDistance)
        
        // transform and add segments
        for _ in 1...Int(rect.height/stripeDistance) {
            stripePattern.append(baseLine)
            stripePattern.apply(move)
        }
        
        return stripePattern
    }
    
    override func draw(_ rect: CGRect) {
        let roundedRect = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius)
        roundedRect.addClip()
        UIColor.white.setFill()
        roundedRect.fill()
        
        // add border
        if (border == nil) {
            border = CAShapeLayer()
            self.layer.addSublayer(border!)
        }
        border?.frame = bounds
        border?.path = roundedRect.cgPath
        border?.fillColor = UIColor.clear.cgColor
        border!.strokeColor = borderColor.cgColor
        border!.lineWidth = borderWitdh
        if isFaceUp {
            configureShapePath()
        } else {
            // face down
            // @todo: add card background image
                border?.fillColor = UIColor.green.cgColor
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
}

extension SetCardView {
    
    private struct SizeRatio {
        static let strokeWidthToBoundsHeight: CGFloat = 0.01
        static let shapeSizeToCardSize: CGFloat = 0.38
        static let cornerRadiusToBoundsHeight: CGFloat = 0.06
        static let shapeOffsetToBoundsHeight: CGFloat = 0.07
        static let stripesDistanceToBoundsHeight: CGFloat = 0.015
        static let stripesWidthToBoundsHeight: CGFloat = 0.005
        static let borderWidthToBoundsHeight: CGFloat = 0.01
    }
    
    private var borderWitdh: CGFloat {
        return bounds.size.height * SizeRatio.borderWidthToBoundsHeight
    }
    
    private var stripeWidth: CGFloat {
        return bounds.size.height * SizeRatio.stripesWidthToBoundsHeight
    }
    
    private var stripeDistance: CGFloat {
        return bounds.size.height * SizeRatio.stripesDistanceToBoundsHeight
    }
    
    private var strokeWidth: CGFloat {
        return bounds.size.height * SizeRatio.strokeWidthToBoundsHeight
    }
    
    private var shapeSize: CGFloat  {
        return self.bounds.size.width * SizeRatio.shapeSizeToCardSize
    }
    
    private var cornerRadius: CGFloat {
        return bounds.size.height * SizeRatio.cornerRadiusToBoundsHeight
    }
    
    private var shapeOffset: CGFloat {
        return bounds.size.height * SizeRatio.shapeOffsetToBoundsHeight
    }
    
    enum CardSymbol {
        case rectangle
        case circle
        case triangle
        
        static let allValues = [rectangle, circle, triangle]
    }
    
    enum SymbolColor {
        case color1
        case color2
        case color3
        
        static let allValues = [color1, color2, color3]
        
    }
    
        enum SymbolDisplay {
        case filled
        case stroked
        case striped
        
        static let allValues = [filled, stroked, striped]
    }
}

extension SetCardView.SymbolColor {
    var color : UIColor {
        get {
            switch self {
            case .color1:
                return UIColor.red
            case .color2:
                return UIColor.green
            case .color3:
                return UIColor.blue
            }
        }
    }
}

extension CGPoint {
    func offsetBy(dx: CGFloat, dy: CGFloat) -> CGPoint {
        return CGPoint(x: x+dx, y: y+dy)
    }
}
