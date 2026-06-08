import re
import os

files_to_process = {
    "Widgets/AntigravityWidget.swift": ("AntigravityEntry", "AntigravityWidget", "Shared/AntigravityUI.swift"),
    "Widgets/GeminiWidget.swift": ("GeminiEntry", "GeminiWidget", "Shared/GeminiUI.swift"),
    "Widgets/CodexWidget.swift": ("CodexEntry", "CodexWidget", "Shared/CodexUI.swift"),
    "Widgets/BlackSSL.swift": ("SimpleEntry", "BlackSSL", "Shared/BlackSSLUI.swift")
}

for widget_file, (entry_name, widget_name, shared_file) in files_to_process.items():
    if not os.path.exists(widget_file):
        print(f"File {widget_file} not found")
        continue
        
    with open(widget_file, "r") as f:
        content = f.read()

    # Find the Entry and EntryView logic
    # It usually starts with `struct <entry_name>: TimelineEntry` and ends right before `struct <widget_name>: Widget`
    pattern = r'(struct ' + entry_name + r': TimelineEntry \{.*?\n)struct ' + widget_name + r': Widget'
    match = re.search(pattern, content, re.DOTALL)
    
    if match:
        ui_code = match.group(1)
        
        # Write to Shared/
        with open(shared_file, "w") as f:
            f.write("import SwiftUI\nimport WidgetKit\n\n")
            f.write(ui_code)
            
        # Remove from Widget file
        new_content = content.replace(ui_code, "")
        
        # Also need to make sure the SimpleEntry in BlackSSL is renamed to BlackSSLEntry in the Shared UI and BlackSSL.swift
        if widget_file == "Widgets/BlackSSL.swift":
            # Rename SimpleEntry to BlackSSLEntry in shared file
            with open(shared_file, "r") as f:
                shared_content = f.read()
            shared_content = shared_content.replace("SimpleEntry", "BlackSSLEntry")
            with open(shared_file, "w") as f:
                f.write(shared_content)
                
            # Rename SimpleEntry to BlackSSLEntry in Widget file
            new_content = new_content.replace("SimpleEntry", "BlackSSLEntry")

        with open(widget_file, "w") as f:
            f.write(new_content)
            
        print(f"Successfully split {widget_file} into {shared_file}")
    else:
        print(f"Could not find matching code in {widget_file}")

