import XCTest
@testable import ShishutsukanKit

/// Integration tests that verify ShishutsukanKit works with actual shishutsukan server
/// These tests require a running shishutsukan server on localhost:8000
final class IntegrationTests: XCTestCase {
    
    var client: ShishutsukanClient!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Initialize client with localhost server
        client = try ShishutsukanClient(baseURLString: "http://localhost:8000")
    }
    
    override func tearDown() async throws {
        client = nil
        try await super.tearDown()
    }
    
    // MARK: - Genre Integration Tests
    
    func testGetGenres() async throws {
        // Get genres from server
        let genres = try await client.getGenres()
        
        // Server should have default genres initialized
        XCTAssertFalse(genres.isEmpty, "Server should have default genres")
        
        // Verify genre structure
        for genre in genres {
            XCTAssertGreaterThan(genre.id, 0, "Genre should have valid ID")
            XCTAssertFalse(genre.name.isEmpty, "Genre should have name")
            XCTAssertFalse(genre.createdAt.isEmpty, "Genre should have creation timestamp")
        }
    }
    
    func testAddGenre() async throws {
        // Create a unique genre name for this test
        let uniqueName = "TestGenre_\(UUID().uuidString.prefix(8))"
        let newGenre = Genre(name: uniqueName)
        
        // Add genre
        let result = try await client.addGenre(newGenre)
        XCTAssertEqual(result.message, "ok", "Genre should be added successfully")
        
        // Verify it appears in the list
        let genres = try await client.getGenres()
        XCTAssertTrue(genres.contains { $0.name == uniqueName }, "Added genre should appear in list")
        
        // Clean up: delete the added genre
        if let addedGenre = genres.first(where: { $0.name == uniqueName }) {
            _ = try await client.deleteGenre(id: addedGenre.id)
        }
    }
    
    func testDeleteGenre() async throws {
        // Add a genre first
        let uniqueName = "ToDelete_\(UUID().uuidString.prefix(8))"
        let newGenre = Genre(name: uniqueName)
        _ = try await client.addGenre(newGenre)
        
        // Find the added genre
        let genres = try await client.getGenres()
        guard let genreToDelete = genres.first(where: { $0.name == uniqueName }) else {
            XCTFail("Failed to find added genre")
            return
        }
        
        // Delete it
        let result = try await client.deleteGenre(id: genreToDelete.id)
        XCTAssertEqual(result.message, "deleted", "Genre should be deleted successfully")
        
        // Verify it's removed from the list
        let genresAfterDeletion = try await client.getGenres()
        XCTAssertFalse(genresAfterDeletion.contains { $0.id == genreToDelete.id }, "Deleted genre should not appear in list")
    }
    
    // MARK: - Expense Integration Tests
    
    func testGetExpenses() async throws {
        // Get expenses from server
        let expenses = try await client.getExpenses()
        
        // This is a valid operation even if the list is empty
        XCTAssertNotNil(expenses, "Should get expenses list (can be empty)")
    }
    
    func testAddExpense() async throws {
        // Add an expense
        let expense = Expense(date: "2025-01-15", genre: "食費", amount: 1000)
        let result = try await client.addExpense(expense)
        XCTAssertEqual(result.message, "ok", "Expense should be added successfully")
        
        // Verify it appears in the list
        let expenses = try await client.getExpenses()
        XCTAssertTrue(expenses.contains { 
            $0.date == expense.date && $0.genre == expense.genre && $0.amount == expense.amount
        }, "Added expense should appear in list")
        
        // Clean up: delete the added expense
        if let addedExpense = expenses.first(where: { 
            $0.date == expense.date && $0.genre == expense.genre && $0.amount == expense.amount
        }) {
            _ = try await client.deleteExpense(id: addedExpense.id)
        }
    }
    
    func testDeleteExpense() async throws {
        // Add an expense first
        let expense = Expense(date: "2025-01-20", genre: "交通費", amount: 500)
        _ = try await client.addExpense(expense)
        
        // Find the added expense
        let expenses = try await client.getExpenses()
        guard let expenseToDelete = expenses.first(where: { 
            $0.date == expense.date && $0.genre == expense.genre && $0.amount == expense.amount
        }) else {
            XCTFail("Failed to find added expense")
            return
        }
        
        // Delete it
        let result = try await client.deleteExpense(id: expenseToDelete.id)
        XCTAssertEqual(result.message, "deleted", "Expense should be deleted successfully")
        
        // Verify it's removed from the list
        let expensesAfterDeletion = try await client.getExpenses()
        XCTAssertFalse(expensesAfterDeletion.contains { $0.id == expenseToDelete.id }, "Deleted expense should not appear in list")
    }
    
    // MARK: - Complete Workflow Test
    
    func testCompleteWorkflow() async throws {
        // This test simulates a complete workflow of the client
        
        // 1. Get initial state
        let initialGenres = try await client.getGenres()
        _ = try await client.getExpenses()
        
        XCTAssertFalse(initialGenres.isEmpty, "Server should have default genres")
        
        // 2. Add a custom genre
        let customGenreName = "統合テスト_\(UUID().uuidString.prefix(8))"
        let customGenre = Genre(name: customGenreName)
        let addGenreResult = try await client.addGenre(customGenre)
        XCTAssertEqual(addGenreResult.message, "ok")
        
        // 3. Verify genre was added
        let genresAfterAdd = try await client.getGenres()
        XCTAssertEqual(genresAfterAdd.count, initialGenres.count + 1)
        guard let addedGenre = genresAfterAdd.first(where: { $0.name == customGenreName }) else {
            XCTFail("Custom genre not found")
            return
        }
        
        // 4. Add expenses using the custom genre
        let expense1 = Expense(date: "2025-01-21", genre: customGenreName, amount: 1234)
        let expense2 = Expense(date: "2025-01-22", genre: customGenreName, amount: 5678)
        
        _ = try await client.addExpense(expense1)
        _ = try await client.addExpense(expense2)
        
        // 5. Verify expenses were added
        let expensesAfterAdd = try await client.getExpenses()
        let addedExpenses = expensesAfterAdd.filter { $0.genre == customGenreName }
        XCTAssertEqual(addedExpenses.count, 2)
        
        // 6. Delete expenses
        for expense in addedExpenses {
            _ = try await client.deleteExpense(id: expense.id)
        }
        
        // 7. Verify expenses were deleted
        let expensesAfterDelete = try await client.getExpenses()
        XCTAssertFalse(expensesAfterDelete.contains { $0.genre == customGenreName })
        
        // 8. Delete custom genre
        let deleteGenreResult = try await client.deleteGenre(id: addedGenre.id)
        XCTAssertEqual(deleteGenreResult.message, "deleted")
        
        // 9. Verify genre was deleted
        let genresAfterDelete = try await client.getGenres()
        XCTAssertEqual(genresAfterDelete.count, initialGenres.count)
    }
    
    // MARK: - Error Handling Tests
    
    func testDeleteNonExistentExpense() async throws {
        // Try to delete an expense with a very high ID that doesn't exist
        let result = try await client.deleteExpense(id: 999999)
        
        // Server returns "deleted" even for non-existent IDs
        XCTAssertEqual(result.message, "deleted")
    }
    
    func testAddDuplicateGenre() async throws {
        // Try to add a genre that already exists
        let genres = try await client.getGenres()
        guard let existingGenre = genres.first else {
            XCTFail("No genres available for testing")
            return
        }
        
        let duplicateGenre = Genre(name: existingGenre.name)
        
        // Server throws error for duplicate genres
        do {
            let result = try await client.addGenre(duplicateGenre)
            // If we get here, check for error in response
            XCTAssertNotNil(result.error, "Should get error for duplicate genre")
        } catch ShishutsukanError.serverError(let message) {
            // Expected error - server returned error message
            XCTAssertTrue(message.contains("already exists"), "Error should mention duplicate genre")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testDeleteGenreInUse() async throws {
        // Add a custom genre
        let genreName = "InUse_\(UUID().uuidString.prefix(8))"
        _ = try await client.addGenre(Genre(name: genreName))
        
        // Find the genre
        let genres = try await client.getGenres()
        guard let genre = genres.first(where: { $0.name == genreName }) else {
            XCTFail("Failed to find added genre")
            return
        }
        
        // Add an expense using this genre
        let expense = Expense(date: "2025-01-23", genre: genreName, amount: 100)
        _ = try await client.addExpense(expense)
        
        // Try to delete the genre (should fail because it's in use)
        do {
            let result = try await client.deleteGenre(id: genre.id)
            // If we get here, check for error in response
            XCTAssertNotNil(result.error, "Should get error when deleting genre in use")
        } catch ShishutsukanError.serverError(let message) {
            // Expected error - server returned error message
            XCTAssertTrue(message.contains("in use"), "Error should mention genre is in use")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Clean up: delete the expense and genre
        let expenses = try await client.getExpenses()
        if let expenseToDelete = expenses.first(where: { $0.genre == genreName }) {
            _ = try await client.deleteExpense(id: expenseToDelete.id)
            _ = try await client.deleteGenre(id: genre.id)
        }
    }
}
