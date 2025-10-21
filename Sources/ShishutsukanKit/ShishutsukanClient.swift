import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// 支出管理API クライアント
public actor ShishutsukanClient {
    private let baseURL: URL
    private let session: URLSession
    
    /// イニシャライザ
    /// - Parameters:
    ///   - baseURL: APIのベースURL（例: "http://localhost:8000"）
    ///   - session: URLSession（デフォルト: .shared）
    public init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }
    
    /// イニシャライザ（文字列から）
    /// - Parameters:
    ///   - baseURLString: APIのベースURL文字列
    ///   - session: URLSession（デフォルト: .shared）
    /// - Throws: ShishutsukanError.invalidURL
    public init(baseURLString: String, session: URLSession = .shared) throws {
        guard let url = URL(string: baseURLString) else {
            throw ShishutsukanError.invalidURL
        }
        self.init(baseURL: url, session: session)
    }
    
    // MARK: - Expense APIs
    
    /// 支出データを追加
    /// - Parameter expense: 追加する支出データ
    /// - Throws: ShishutsukanError
    /// - Returns: APIメッセージ
    public func addExpense(_ expense: Expense) async throws -> APIMessage {
        let url = baseURL.appendingPathComponent("/expenses")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(expense)
        
        let (data, response) = try await session.data(for: request)
        
        try validateResponse(response)
        
        let message = try JSONDecoder().decode(APIMessage.self, from: data)
        if let error = message.error {
            throw ShishutsukanError.serverError(error)
        }
        return message
    }
    
    /// 支出データの一覧を取得
    /// - Throws: ShishutsukanError
    /// - Returns: 支出データの配列
    public func getExpenses() async throws -> [ExpenseWithId] {
        let url = baseURL.appendingPathComponent("/expenses")
        let request = URLRequest(url: url)
        
        let (data, response) = try await session.data(for: request)
        
        try validateResponse(response)
        
        do {
            return try JSONDecoder().decode([ExpenseWithId].self, from: data)
        } catch {
            throw ShishutsukanError.decodingError(error)
        }
    }
    
    /// 支出データを削除
    /// - Parameter id: 削除する支出データのID
    /// - Throws: ShishutsukanError
    /// - Returns: APIメッセージ
    public func deleteExpense(id: Int) async throws -> APIMessage {
        let url = baseURL.appendingPathComponent("/expenses/\(id)")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let (data, response) = try await session.data(for: request)
        
        try validateResponse(response)
        
        let message = try JSONDecoder().decode(APIMessage.self, from: data)
        if let error = message.error {
            throw ShishutsukanError.serverError(error)
        }
        return message
    }
    
    // MARK: - Genre APIs
    
    /// ジャンルの一覧を取得
    /// - Throws: ShishutsukanError
    /// - Returns: ジャンルデータの配列
    public func getGenres() async throws -> [GenreWithId] {
        let url = baseURL.appendingPathComponent("/genres")
        let request = URLRequest(url: url)
        
        let (data, response) = try await session.data(for: request)
        
        try validateResponse(response)
        
        do {
            return try JSONDecoder().decode([GenreWithId].self, from: data)
        } catch {
            throw ShishutsukanError.decodingError(error)
        }
    }
    
    /// ジャンルを追加
    /// - Parameter genre: 追加するジャンルデータ
    /// - Throws: ShishutsukanError
    /// - Returns: APIメッセージ
    public func addGenre(_ genre: Genre) async throws -> APIMessage {
        let url = baseURL.appendingPathComponent("/genres")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(genre)
        
        let (data, response) = try await session.data(for: request)
        
        try validateResponse(response)
        
        let message = try JSONDecoder().decode(APIMessage.self, from: data)
        if let error = message.error {
            throw ShishutsukanError.serverError(error)
        }
        return message
    }
    
    /// ジャンルを削除
    /// - Parameter id: 削除するジャンルのID
    /// - Throws: ShishutsukanError
    /// - Returns: APIメッセージ
    public func deleteGenre(id: Int) async throws -> APIMessage {
        let url = baseURL.appendingPathComponent("/genres/\(id)")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let (data, response) = try await session.data(for: request)
        
        try validateResponse(response)
        
        let message = try JSONDecoder().decode(APIMessage.self, from: data)
        if let error = message.error {
            throw ShishutsukanError.serverError(error)
        }
        return message
    }
    
    // MARK: - Helper Methods
    
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ShishutsukanError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw ShishutsukanError.httpError(statusCode: httpResponse.statusCode)
        }
    }
}
