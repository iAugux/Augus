import os
import re

def extract_and_save(source_path, split_marker, new_file_path, new_imports):
    if not os.path.exists(source_path): return
    with open(source_path, 'r') as f:
        content = f.read()
    
    parts = content.split(split_marker, 1)
    if len(parts) > 1:
        with open(source_path, 'w') as f:
            f.write(parts[0].rstrip() + "\n")
            
        with open(new_file_path, 'w') as f:
            f.write(new_imports + "\n\n" + split_marker + parts[1])
        print(f"Split {new_file_path} from {source_path}")

# Split MenuBarViewModel
extract_and_save(
    'Augus/AugusApp.swift', 
    'class MenuBarViewModel: ObservableObject {', 
    'Augus/MenuBarViewModel.swift', 
    'import SwiftUI\nimport Combine\nimport WidgetKit'
)

# Split MenuBarWidgetView
extract_and_save(
    'Augus/MenuBarViewModel.swift', 
    'struct GlassWidgetModifier: ViewModifier {', 
    'Augus/MenuBarWidgetView.swift', 
    'import SwiftUI\nimport WidgetKit'
)

# Shared UI files
extract_and_save('Shared/BlackSSLData.swift', 'struct BlackSSLEntry: TimelineEntry {', 'Shared/BlackSSLUI.swift', 'import SwiftUI\nimport WidgetKit\nimport AppIntents')
extract_and_save('Shared/CodexData.swift', 'struct CodexEntry: TimelineEntry {', 'Shared/CodexUI.swift', 'import SwiftUI\nimport WidgetKit\nimport AppIntents')
extract_and_save('Shared/GeminiData.swift', 'struct GeminiEntry: TimelineEntry {', 'Shared/GeminiUI.swift', 'import SwiftUI\nimport WidgetKit\nimport AppIntents')
extract_and_save('Shared/AntigravityData.swift', 'struct AntigravityEntry: TimelineEntry {', 'Shared/AntigravityUI.swift', 'import SwiftUI\nimport WidgetKit\nimport AppIntents')

# Extract Intents
extract_and_save('Shared/CodexUI.swift', 'struct RefreshCodexIntent: AppIntent {', 'Widgets/RefreshCodexIntent.swift', 'import AppIntents\nimport WidgetKit')
extract_and_save('Shared/BlackSSLUI.swift', 'struct RefreshBlackSSLIntent: AppIntent {', 'Widgets/RefreshBlackSSLIntent.swift', 'import AppIntents\nimport WidgetKit')
