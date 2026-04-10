//
//  ViewController.swift
//  Sample Project iOS
//
//  Copyright (c) 2013 Nima Yousefi. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController {
    private var webView: WKWebView!

    override func loadView() {
        webView = WKWebView()
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let path = Bundle.main.path(forResource: "Big Fish.fountain", ofType: nil) else { return }
        let script     = FNScript(file: path)
        let htmlScript = FNHTMLScript(script: script)
        webView.loadHTMLString(htmlScript.html(), baseURL: nil)
    }
}
