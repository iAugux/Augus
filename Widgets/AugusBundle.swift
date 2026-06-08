// Created by Augus on 5/30/26
// Copyright © 2026 Augus <iAugux@gmail.com>

import WidgetKit
import SwiftUI

@main
struct AugusBundle: WidgetBundle {
    var body: some Widget {
        BlackSSL()
        CodexWidget()
        GeminiWidget()
#if os(macOS)
        AntigravityWidget()
#endif
    }
}
