import XCTest
@testable import ShishutsukanKit

final class ShishutsukanKitTests: XCTestCase {
    
    // MARK: - Model Tests
    
    func testExpenseModel() {
        let expense = Expense(date: "2025-01-15", genre: "食費", amount: 1000)
        XCTAssertEqual(expense.date, "2025-01-15")
        XCTAssertEqual(expense.genre, "食費")
        XCTAssertEqual(expense.amount, 1000)
    }
    
    func testExpenseWithIdModel() {
        let expense = ExpenseWithId(id: 1, date: "2025-01-15", genre: "食費", amount: 1000)
        XCTAssertEqual(expense.id, 1)
        XCTAssertEqual(expense.date, "2025-01-15")
        XCTAssertEqual(expense.genre, "食費")
        XCTAssertEqual(expense.amount, 1000)
    }
    
    func testGenreModel() {
        let genre = Genre(name: "食費")
        XCTAssertEqual(genre.name, "食費")
    }
    
    func testGenreWithIdModel() {
        let genre = GenreWithId(id: 1, name: "食費", createdAt: "2025-01-15 10:00:00")
        XCTAssertEqual(genre.id, 1)
        XCTAssertEqual(genre.name, "食費")
        XCTAssertEqual(genre.createdAt, "2025-01-15 10:00:00")
    }
    
    // MARK: - JSON Encoding/Decoding Tests
    
    func testExpenseEncoding() throws {
        let expense = Expense(date: "2025-01-15", genre: "食費", amount: 1000)
        let data = try JSONEncoder().encode(expense)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        XCTAssertEqual(json?["date"] as? String, "2025-01-15")
        XCTAssertEqual(json?["genre"] as? String, "食費")
        XCTAssertEqual(json?["amount"] as? Int, 1000)
    }
    
    func testExpenseWithIdDecoding() throws {
        let json = """
        {
            "id": 1,
            "date": "2025-01-15",
            "genre": "食費",
            "amount": 1000
        }
        """
        let data = json.data(using: .utf8)!
        let expense = try JSONDecoder().decode(ExpenseWithId.self, from: data)
        
        XCTAssertEqual(expense.id, 1)
        XCTAssertEqual(expense.date, "2025-01-15")
        XCTAssertEqual(expense.genre, "食費")
        XCTAssertEqual(expense.amount, 1000)
    }
    
    func testGenreWithIdDecoding() throws {
        let json = """
        {
            "id": 1,
            "name": "食費",
            "created_at": "2025-01-15 10:00:00"
        }
        """
        let data = json.data(using: .utf8)!
        let genre = try JSONDecoder().decode(GenreWithId.self, from: data)
        
        XCTAssertEqual(genre.id, 1)
        XCTAssertEqual(genre.name, "食費")
        XCTAssertEqual(genre.createdAt, "2025-01-15 10:00:00")
    }
    
    // MARK: - Client Initialization Tests
    
    func testClientInitWithURL() {
        let url = URL(string: "http://localhost:8000")!
        let client = ShishutsukanClient(baseURL: url)
        XCTAssertNotNil(client)
    }
    
    func testClientInitWithString() throws {
        let client = try ShishutsukanClient(baseURLString: "http://localhost:8000")
        XCTAssertNotNil(client)
    }
    
    func testClientInitWithInvalidString() {
        XCTAssertThrowsError(try ShishutsukanClient(baseURLString: "")) { error in
            XCTAssertTrue(error is ShishutsukanError)
            if case ShishutsukanError.invalidURL = error {
                // Expected error
            } else {
                XCTFail("Expected invalidURL error")
            }
        }
    }
    
    // MARK: - Error Tests
    
    func testErrorDescriptions() {
        XCTAssertNotNil(ShishutsukanError.invalidURL.errorDescription)
        XCTAssertNotNil(ShishutsukanError.invalidResponse.errorDescription)
        XCTAssertNotNil(ShishutsukanError.httpError(statusCode: 404).errorDescription)
        XCTAssertNotNil(ShishutsukanError.serverError("test error").errorDescription)
    }
}
