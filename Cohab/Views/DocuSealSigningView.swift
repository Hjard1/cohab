import SwiftUI
import WebKit

/// Embeds the DocuSeal signing form inside a WKWebView.
/// Loads the official DocuSeal JS widget with the partner's embed_src URL.
struct DocuSealSigningView: UIViewRepresentable {
    let signingURL: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        // Allow inline media so the signature pad works
        config.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = .clear

        webView.loadHTMLString(html, baseURL: URL(string: "https://docuseal.eu"))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    // MARK: HTML template

    private var html: String {
        """
        <!DOCTYPE html>
        <html>
          <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
            <script src="https://cdn.docuseal.com/js/form.js"></script>
            <style>
              * { box-sizing: border-box; }
              body { margin: 0; padding: 0; background: #F2F2F7; }
              docuseal-form { display: block; width: 100%; }
            </style>
          </head>
          <body>
            <docuseal-form data-src="\(signingURL)"></docuseal-form>
          </body>
        </html>
        """
    }

    // MARK: Coordinator

    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {}

        func webView(_ webView: WKWebView,
                     decidePolicyFor action: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Let DocuSeal's own redirects through; block external navigation
            guard let url = action.request.url else { return decisionHandler(.allow) }
            let host = url.host ?? ""
            let allowed = host.contains("docuseal") || host.isEmpty || url.isFileURL
            decisionHandler(allowed ? .allow : .cancel)
        }
    }
}

#Preview {
    DocuSealSigningView(signingURL: "https://docuseal.eu/s/example")
}
