import AppKit
import Fountain
import WebKit

@main
enum FountainSampleMacApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = SampleDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        app.run()
    }
}

final class SampleDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let webView = WKWebView(frame: .zero)
        let rect = NSRect(x: 0, y: 0, width: 920, height: 740)
        let style: NSWindow.StyleMask = [.titled, .closable, .miniaturizable, .resizable]
        let win = NSWindow(contentRect: rect, styleMask: style, backing: .buffered, defer: false)
        win.title = "Fountain (SwiftPM sample)"
        win.center()
        win.contentView = webView
        win.makeKeyAndOrderFront(nil)
        window = win

        guard let url = Bundle.module.url(forResource: "Big Fish", withExtension: "fountain") else { return }
        let script = FNScript(file: url.path)
        let htmlScript = FNHTMLScript(script: script)
        webView.loadHTMLString(htmlScript.html(), baseURL: nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
