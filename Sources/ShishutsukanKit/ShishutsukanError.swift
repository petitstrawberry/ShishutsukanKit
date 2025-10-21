import Foundation

/// ShishutsukanKit のエラー型
public enum ShishutsukanError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
    case networkError(Error)
    case serverError(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case .invalidResponse:
            return "無効なレスポンスです"
        case .httpError(let statusCode):
            return "HTTPエラー: \(statusCode)"
        case .decodingError(let error):
            return "デコードエラー: \(error.localizedDescription)"
        case .networkError(let error):
            return "ネットワークエラー: \(error.localizedDescription)"
        case .serverError(let message):
            return "サーバーエラー: \(message)"
        }
    }
}
