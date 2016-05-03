//
//  ViewController.swift
//  Augus
//
//  Created by Augus on 2/21/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    private let configuration: PasscodeLockConfigurationType!
    
    @IBOutlet weak var passcodeIndicator: UIImageView!
    
    @IBOutlet weak var tumblrImageView: UIImageView! {
        didSet {
            let hidden = GroupUserDefaults?.getBool(kHideTumblrKey, defaultKeyValue: false) ?? false
            tumblrImageView.alpha = hidden ? 0.3 : 1
        }
    }
    
    init(configuration: PasscodeLockConfigurationType) {
        
        self.configuration = configuration
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        let repository = UserDefaultsPasscodeRepository()
        configuration = PasscodeLockConfiguration(repository: repository)
        
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configurePasscodeIndicator()
        configureTumblrImageView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        updatePasscodeView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    private func configurePasscodeIndicator() {
        passcodeIndicator.image = UIImage(named: "touch")?.imageWithRenderingMode(.AlwaysTemplate)
        passcodeIndicator.userInteractionEnabled = true
        
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(passcodeIndicatorDidSingleTap))
        passcodeIndicator.addGestureRecognizer(singleTap)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(passcodeIndicatorDidLongPress(_:)))
        passcodeIndicator.addGestureRecognizer(longPress)
        
        longPress.requireGestureRecognizerToFail(singleTap)
    }
}


// MARK: - Hide Tumblr

extension ViewController {
    
    private func configureTumblrImageView() {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(hideTumblrOrNot))
        tumblrImageView.addGestureRecognizer(recognizer)
        tumblrImageView.userInteractionEnabled = true
    }
    
    @objc private func hideTumblrOrNot() {
        let hidden = GroupUserDefaults?.getBool(kHideTumblrKey, defaultKeyValue: false) ?? false
        tumblrImageView.alpha = !hidden ? 0.3 : 1
        GroupUserDefaults?.setBool(!hidden, forKey: kHideTumblrKey)
        GroupUserDefaults?.synchronize()
    }

}


// MARK: - Touch ID

extension ViewController {
    
    @objc private func passcodeIndicatorDidSingleTap() {
        
        let passcodeVC: PasscodeLockViewController
        
        if !configuration.repository.hasPasscode {
            
            passcodeVC = PasscodeLockViewController(state: .SetPasscode, configuration: configuration)
            
        } else {
            
            passcodeVC = PasscodeLockViewController(state: .RemovePasscode, configuration: configuration)
            
            passcodeVC.successCallback = { lock in
                
                lock.repository.deletePasscode()
                self.updatePasscodeView()
            }
        }
        
        presentViewController(passcodeVC, animated: true, completion: nil)
    }
    
    @objc private func passcodeIndicatorDidLongPress(sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case .Began:
            
            if configuration.repository.hasPasscode {
                // change passcode
                
                let repo = UserDefaultsPasscodeRepository()
                let config = PasscodeLockConfiguration(repository: repo)
                
                let passcodeLock = PasscodeLockViewController(state: .ChangePasscode, configuration: config)
                
                presentViewController(passcodeLock, animated: true, completion: nil)
                
            } else {
                // add passcode
                passcodeIndicatorDidSingleTap()
            }
        default:
            return
        }
    }
    
    private func updatePasscodeView() {

        let hasPasscode = configuration.repository.hasPasscode
        passcodeIndicator.tintColor = hasPasscode ? UIColor(red: 0.0, green: 1.0, blue: 1.0, alpha: 1.0) : UIColor.grayColor()
    }
    
    
}
