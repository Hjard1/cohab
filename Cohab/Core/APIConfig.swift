import Foundation

/// Backend URL for the cohab FastAPI server.
/// Replace with your deployed URL before distributing.
enum APIConfig {
    static let backendURL = URL(string: "http://localhost:8000")!
}
