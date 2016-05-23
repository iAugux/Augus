//
//  TodayViewController.swift
//  Settings
//
//  Created by Augus on 2/21/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit
import NotificationCenter


class TodayViewController: UIViewController, NCWidgetProviding {
        
    @IBOutlet weak var surgeButton: UIButton!
    @IBOutlet weak var macIDLockButton: UIButton!
    @IBOutlet weak var macIDWakeButton: UIButton!
    @IBOutlet weak var macIDClipboardButton: UIButton!
    
    @IBOutlet weak var tumblrButton: UIButton!
    
    @IBOutlet weak var surgeAutoCloseSwitch: UISwitch! {
        didSet {
            surgeAutoCloseSwitch.shouldSwitch(kSurgeAutoClose, defaultBool: kSurgeAutoCloseDefaultBool)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        preferredContentSize = CGSizeMake(0, 130.0)
        configureSurgePanel()
        configureMacIDPanel()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
            let hideTumblr = GroupUserDefaults?.getBool(kHideTumblrKey, defaultKeyValue: false) ?? false
            tumblrButton.hidden = hideTumblr
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.

        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData

        completionHandler(NCUpdateResult.NewData)
    }
    
    // MARK: - NCWidgetProviding
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsetsZero
    }

}

extension TodayViewController {
    
    func openSettingWithURL(url: String) {
        if let url = NSURL(string: url) {
            extensionContext?.openURL(url, completionHandler: nil)
        }
    }
}
