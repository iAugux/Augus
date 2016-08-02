//
//  PasscodeSignButton.swift
//  PasscodeLock
//
//  Created by Yanko Dimitrov on 8/28/15.
//  Copyright © 2015 Yanko Dimitrov. All rights reserved.
//

import UIKit

@IBDesignable
public class PasscodeSignButton: UIButton {
    
    @IBInspectable
    public var passcodeSign: String = "1"
    
    @IBInspectable
    public var borderColor: UIColor = UIColor.white {
        didSet {
            setupView()
        }
    }
    
    @IBInspectable
    public var borderRadius: CGFloat = 30 {
        didSet {
            setupView()
        }
    }
    
    @IBInspectable
    public var highlightBackgroundColor: UIColor = UIColor.clear {
        didSet {
            setupView()
        }
    }
    
    public override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        setupView()
        setupActions()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        setupActions()
    }
    
    public override var intrinsicContentSize: CGSize {
        return CGSize(width: 60, height: 60)
    }
    
    private var defaultBackgroundColor = UIColor.clear
    
    private func setupView() {
        
        layer.borderWidth = 1
        layer.cornerRadius = borderRadius
        layer.borderColor = borderColor.cgColor
        
        if let backgroundColor = backgroundColor {
            
            defaultBackgroundColor = backgroundColor
        }
    }
    
    private func setupActions() {
        
        addTarget(self, action: #selector(PasscodeSignButton.handleTouchDown), for: .touchDown)
        addTarget(self, action: #selector(PasscodeSignButton.handleTouchUp), for: [.touchUpInside, .touchDragOutside, .touchCancel])
    }
    
    func handleTouchDown() {
        
        animateBackgroundColor(highlightBackgroundColor)
    }
    
    func handleTouchUp() {
        
        animateBackgroundColor(defaultBackgroundColor)
    }
    
    private func animateBackgroundColor(_ color: UIColor) {
        
        UIView.animate(
            withDuration: 0.3,
            delay: 0.0,
            usingSpringWithDamping: 1,
            initialSpringVelocity: 0.0,
            options: [.allowUserInteraction, .beginFromCurrentState],
            animations: {
                
                self.backgroundColor = color
            },
            completion: nil
        )
    }
}
