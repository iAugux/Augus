// Created by Augus on 6/03/26
// Copyright © 2026 Augus <iAugux@gmail.com>

import SwiftUI

extension View {
    func disableAutocapitalizationIfNeeded() -> some View {
#if os(iOS)
        return self.autocapitalization(.none)
#else
        return self
#endif
    }
}
