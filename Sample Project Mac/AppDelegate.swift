//
//  AppDelegate.swift
//  Sample Project Mac
//
//  Copyright (c) 2012 Nima Yousefi. All rights reserved.
//

import AppKit
import Fountain
import WebKit

@main
@objc(AppDelegate)
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet var webView: WKWebView!

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let path = Bundle.main.path(forResource: "Big Fish.fountain", ofType: nil) else { return }
        let script     = FNScript(file: path)
        let htmlScript = FNHTMLScript(script: script)
        webView.loadHTMLString(htmlScript.html(), baseURL: nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
