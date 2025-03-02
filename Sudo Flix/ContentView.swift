//
//  ContentView.swift
//  Sudo Flix
//
//  Created by Max Dawson on 01/03/2025.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var topBackgroundColor: Color

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = true
        webView.backgroundColor = UIColor.clear
        webView.isOpaque = false
        webView.navigationDelegate = context.coordinator

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let js = """
            (function() {
                var element = document.elementFromPoint(0, 2);
                while (element && getComputedStyle(element).backgroundColor === 'rgba(0, 0, 0, 0)') {
                    element = element.parentElement;
                }
                getComputedStyle(element).backgroundColor;
            })();
            """
            webView.evaluateJavaScript(js) { (result, error) in
                if let colorString = result as? String {
                    self.parent.topBackgroundColor = Color(UIColor(hex: colorString))
                }
            }
        }
    }
}

extension UIColor {
    convenience init(hex: String) {
        let hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)

        if hexSanitized.hasPrefix("rgb") {
            let components = hexSanitized
                .replacingOccurrences(of: "rgba(", with: "")
                .replacingOccurrences(of: "rgb(", with: "")
                .replacingOccurrences(of: ")", with: "")
                .split(separator: ",")
                .compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }

            if components.count >= 3 {
                let red = CGFloat(components[0]) / 255.0
                let green = CGFloat(components[1]) / 255.0
                let blue = CGFloat(components[2]) / 255.0
                let alpha = components.count == 4 ? CGFloat(components[3]) : 1.0
                self.init(red: red, green: green, blue: blue, alpha: alpha)
                return
            }
        }

        self.init(red: 0, green: 0, blue: 0, alpha: 1.0)
    }
}

extension Color {
    init(hex: String) {
        self.init(UIColor(hex: hex))
    }
}

struct ContentView: View {
    @State private var url = URL(string: "https://pseudo-flix.pro/")!
    @State private var topBackgroundColor: Color = Color(hex: "181838")

    var body: some View {
        WebView(url: url, topBackgroundColor: $topBackgroundColor)
            .edgesIgnoringSafeArea(.bottom)
            .background(topBackgroundColor)
            .onAppear {
                checkAutoRotate()
            }
    }

    func checkAutoRotate() {
        if url.absoluteString.contains("/media") {
            UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
        } else {
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        }
    }
}

#Preview {
    ContentView()
}
