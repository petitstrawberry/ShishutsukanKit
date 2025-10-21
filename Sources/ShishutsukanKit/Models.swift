import Foundation

/// 支出データモデル
public struct Expense: Codable, Sendable {
    public let date: String
    public let genre: String
    public let amount: Int
    
    public init(date: String, genre: String, amount: Int) {
        self.date = date
        self.genre = genre
        self.amount = amount
    }
}

/// ID付き支出データモデル
public struct ExpenseWithId: Codable, Sendable, Identifiable {
    public let id: Int
    public let date: String
    public let genre: String
    public let amount: Int
    
    public init(id: Int, date: String, genre: String, amount: Int) {
        self.id = id
        self.date = date
        self.genre = genre
        self.amount = amount
    }
}

/// ジャンルデータモデル
public struct Genre: Codable, Sendable {
    public let name: String
    
    public init(name: String) {
        self.name = name
    }
}

/// ID付きジャンルデータモデル
public struct GenreWithId: Codable, Sendable, Identifiable {
    public let id: Int
    public let name: String
    public let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case createdAt = "created_at"
    }
    
    public init(id: Int, name: String, createdAt: String) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
    }
}

/// API レスポンスメッセージ
public struct APIMessage: Codable, Sendable {
    public let message: String?
    public let error: String?
    
    public init(message: String? = nil, error: String? = nil) {
        self.message = message
        self.error = error
    }
}
