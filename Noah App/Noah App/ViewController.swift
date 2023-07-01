//
//  ViewController.swift
//  Noah App
//
//  Created by Danial Fajar on 12/06/2023.
//

import UIKit
import WebKit

class ViewController: UIViewController {

    @IBOutlet weak var webView: WKWebView!
    
    var urlString: String?
    var titlePage: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = titlePage
        
        self.setupWebView()
        self.urlSetup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.isNavigationBarHidden = titlePage == nil ? true : false
    }

    deinit {
        #if DEBUG
        print("🌍🌍🌍 Deinit ViewController 🌍🌍🌍")
        #endif
    }
    
    //MARK: - Setup Function
    func setupWebView() {
        let source: String = "var meta = document.createElement('meta');" +
            "meta.name = 'viewport';" +
            "meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';" +
            "var head = document.getElementsByTagName('head')[0];" +
            "head.appendChild(meta);"
        let script: WKUserScript = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        
        self.webView.navigationDelegate = self
        self.webView.uiDelegate = self
        if #available(iOS 14.0, *) {
            self.webView.configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        } else {
            self.webView.configuration.preferences.javaScriptEnabled = true
        }
        self.webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1" //For Sign In With Google
        self.webView.isOpaque = false
        self.webView.backgroundColor = UIColor.clear
        self.webView.configuration.userContentController.addUserScript(script)
        self.webView.scrollView.refreshControl?.addTarget(self, action: #selector(doRefresh(_:)), for: .valueChanged)
    }
    
    func urlSetup() {
        guard let url = URL(string: urlString ?? "https://app.noah.com") else { return }
        var request = URLRequest(url: url)
        
        request.setValue("true", forHTTPHeaderField: "webview")
        
        self.webView.load(request)
    }
    
    //MARK: - Action Function
    @objc func doRefresh(_ sender: UIRefreshControl) {
        self.webView.reload()
    }
}

//MARK:- WKWebview Navigation Delegate
extension ViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation _: WKNavigation!) {}
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {}
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping ((WKNavigationActionPolicy) -> Void)) {
        
        guard let url = navigationAction.request.url, let urlHost = url.host else {
            decisionHandler(.cancel)
            return
        }
        
        guard !navigationAction.description.contains("signout") else {
            webView.clearDiskCookies(for: urlHost)
            decisionHandler(.allow)
            return
        }
        
        webView.loadDiskCookies(for: urlHost) {
            decisionHandler(.allow)
        }
    }
}

//MARK:- WKWebview WKUIDelegate Delegate
extension ViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        guard let url = webView.url, let urlHost = url.host else {
            decisionHandler(.cancel)
            return
        }
        
        webView.writeDiskCookies(for: urlHost) {
            decisionHandler(.allow)
        }
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let frame = navigationAction.targetFrame,
            frame.isMainFrame {
            return nil
        }
        
        // for _blank target or non-mainFrame target
        guard let vc = self.storyboard?.instantiateViewController(withIdentifier: "ViewController") as? ViewController else { return nil }
        vc.urlString = navigationAction.request.url?.absoluteString
        vc.titlePage = "Noah App"
        vc.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(vc, animated: true)
        return nil
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alertController = UIAlertController(title: "Noah App", message: message, preferredStyle: .alert)

        alertController.addAction(UIAlertAction(title: "OK", style: .cancel) {_ in
            completionHandler()
        })

        self.present(alertController, animated: true, completion: nil)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: "Noah App", message: message, preferredStyle: .alert)

        alertController.addAction(UIAlertAction(title: "OK", style: .default) {_ in
            completionHandler(true)
        })

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel)  {_ in
            completionHandler(false)
        })
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (String?) -> Void) {

        let alertController = UIAlertController(title: nil, message: prompt, preferredStyle: .actionSheet)

        alertController.addTextField { (textField) in
            textField.text = defaultText
        }

        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            if let text = alertController.textFields?.first?.text {
                completionHandler(text)
            } else {
                completionHandler(defaultText)
            }
        }))

        alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
            completionHandler(nil)
        }))

        self.present(alertController, animated: true, completion: nil)
    }
}

extension WKWebView {
    enum PrefKey {
        static let cookie = "cookies"
    }

    func writeDiskCookies(for domain: String, completion: @escaping () -> ()) {
        fetchInMemoryCookies(for: domain) { data in
            UserDefaults.standard.setValue(data, forKey: PrefKey.cookie)
            completion()
        }
    }
    
    func clearDiskCookies(for domain: String) {
        fetchInMemoryCookies(for: domain) { data in
            UserDefaults.standard.removeObject(forKey: PrefKey.cookie)
        }
    }

    func loadDiskCookies(for domain: String, completion: @escaping () -> ()) {
        if let diskCookie = UserDefaults.standard.dictionary(forKey: (PrefKey.cookie)) {
            fetchInMemoryCookies(for: domain) { freshCookie in

                let mergedCookie = diskCookie.merging(freshCookie) { (_, new) in new }

                for (_, cookieConfig) in mergedCookie {
                    let cookie = cookieConfig as! Dictionary<String, Any>

                    var expire : Any? = nil

                    if let expireTime = cookie["Expires"] as? Double {
                        expire = Date(timeIntervalSinceNow: expireTime)
                    }

                    let newCookie = HTTPCookie(properties: [
                        .domain: cookie["Domain"] as Any,
                        .path: cookie["Path"] as Any,
                        .name: cookie["Name"] as Any,
                        .value: cookie["Value"] as Any,
                        .secure: cookie["Secure"] as Any,
                        .expires: expire as Any
                    ])

                    self.configuration.websiteDataStore.httpCookieStore.setCookie(newCookie!)
                }

                completion()
            }

        } else {
            completion()
        }
    }

    func fetchInMemoryCookies(for domain: String, completion: @escaping ([String: Any]) -> ()) {
        var cookieDict = [String: AnyObject]()
        WKWebsiteDataStore.default().httpCookieStore.getAllCookies { (cookies) in
            for cookie in cookies {
                cookieDict[cookie.name] = cookie.properties as AnyObject?
            }
            completion(cookieDict)
        }
    }
}
