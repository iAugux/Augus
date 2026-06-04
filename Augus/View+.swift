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
    
    func hideNavigationBarBackgroundIfNeeded() -> some View {
#if os(iOS)
        return self.toolbarBackground(.hidden, for: .navigationBar)
#else
        return self
#endif
    }
    
    func hideWindowToolbarBackgroundIfNeeded() -> some View {
#if os(macOS)
        if #available(macOS 13.0, *) {
            return self.toolbarBackground(.hidden, for: .windowToolbar)
        } else {
            return self
        }
#else
        return self
#endif
    }
}
