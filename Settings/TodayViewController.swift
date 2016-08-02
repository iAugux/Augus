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
        configureSurgePanel()
        configureMacIDPanel()
        
//        if #available(iOSApplicationExtension 10.0, *) {
//            extensionContext?.widgetLargestAvailableDisplayMode = .expanded
//        }

        preferredContentSize = CGSize(width: 0, height: 40.0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let hideTumblr = GroupUserDefaults?.getBool(kHideTumblrKey, defaultKeyValue: false) ?? false
        tumblrButton.isHidden = hideTumblr
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdate(_ completionHandler: ((NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.

        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData

        completionHandler(NCUpdateResult.newData)
    }
    
    // MARK: - NCWidgetProviding
    func widgetMarginInsets(forProposedMarginInsets defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return .zero
    }

//    @available(iOSApplicationExtension 10.0, *)
//    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
//        
//        // here may be a bug
//        // set maxSize to preferredContentSize, or these actions of `Show More/Less` may be ineffective.
//        preferredContentSize = maxSize
//        
//        preferredContentSize = CGSize(width: 0, height: 130.0)
//    }

}

extension TodayViewController {
    
    func openSettingWithURL(_ url: String) {
        if let url = URL(string: url) {
            extensionContext?.open(url, completionHandler: nil)
        }
    }
}
