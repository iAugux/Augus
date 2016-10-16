//
//  TintedButton.swift
//  Augus
//
//  Created by Augus on 10/17/16.
//  Copyright © 2016 iAugus. All rights reserved.
//

import UIKit

class TintedButton: UIButton {

    override func awakeFromNib() {
        super.awakeFromNib()

        imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)

        guard let image = image(for: .normal) else { return }

        tintColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        setImage(image.withRenderingMode(.alwaysTemplate), for: .normal)
    }
}
