#if os(macOS)
import SwiftUI
import WidgetKit

struct MenuWidgetModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.vertical, 4)
            .padding(.horizontal, 4)
    }
}

extension View {
    func menuWidgetStyle() -> some View {
        self.modifier(MenuWidgetModifier())
    }
}

struct MenuBarWidgetView: View {
    @ObservedObject var viewModel: MenuBarViewModel
    @Environment(\.openWindow) private var openWindow
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                BlackSSLEntryView(entry: viewModel.blackSSLEntry, overrideFamily: WidgetFamily.systemMedium, isMenuBar: true)
                    .menuWidgetStyle()
                Divider()
                CodexEntryView(entry: viewModel.codexEntry, overrideFamily: WidgetFamily.systemMedium, isMenuBar: true)
                    .menuWidgetStyle()
                Divider()
                AntigravityEntryView(entry: viewModel.antigravityEntry, overrideFamily: WidgetFamily.systemMedium, isMenuBar: true)
                    .menuWidgetStyle()
                Divider()
                GeminiEntryView(entry: viewModel.geminiEntry, overrideFamily: WidgetFamily.systemMedium, isMenuBar: true)
                    .menuWidgetStyle()
            }
            .padding(.top, 16)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            
            Divider().opacity(0.5)
            
            // Footer
            HStack {
                Text("Updated: \(formatTime(viewModel.blackSSLEntry.date))")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    openMainApp()
                }) {
                    Image(systemName: "arrow.up.forward.app.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Open Main App")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(width: 360)
        .onAppear {
            viewModel.refreshData()
        }
    }
    
    private func openMainApp() {
        openWindow(id: "main")
        NSApp.activate(ignoringOtherApps: true)
    }
}
#endif
