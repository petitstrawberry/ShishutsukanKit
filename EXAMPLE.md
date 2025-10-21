# ShishutsukanKit 使用例

このファイルでは、ShishutsukanKitの実用的な使用例を紹介します。

## 基本的なCLIツール

```swift
import Foundation
import ShishutsukanKit

@main
struct ExpenseManager {
    static func main() async {
        do {
            // クライアントの初期化
            let client = try ShishutsukanClient(baseURLString: "http://localhost:8000")
            
            // 今日の日付を取得
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let today = formatter.string(from: Date())
            
            // 1. ジャンル一覧を表示
            print("=== 利用可能なジャンル ===")
            let genres = try await client.getGenres()
            for genre in genres {
                print("[\(genre.id)] \(genre.name)")
            }
            
            // 2. 支出を追加
            print("\n=== 支出を追加 ===")
            let expense = Expense(date: today, genre: "食費", amount: 1200)
            let addResult = try await client.addExpense(expense)
            print(addResult.message ?? "追加しました")
            
            // 3. 支出一覧を表示
            print("\n=== 支出一覧 ===")
            let expenses = try await client.getExpenses()
            var total = 0
            for expense in expenses {
                print("[\(expense.id)] \(expense.date) - \(expense.genre): ¥\(expense.amount)")
                total += expense.amount
            }
            print("\n合計: ¥\(total)")
            
        } catch {
            print("エラー: \(error)")
        }
    }
}
```

## SwiftUIアプリケーション

### メインビュー

```swift
import SwiftUI
import ShishutsukanKit

@main
struct ExpenseApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = ExpenseViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                // 支出リスト
                ExpenseListView(viewModel: viewModel)
                
                Divider()
                
                // 支出追加フォーム
                ExpenseFormView(viewModel: viewModel)
            }
            .navigationTitle("支出管理")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { 
                        Task { await viewModel.loadExpenses() }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .task {
            await viewModel.loadData()
        }
    }
}
```

### ビューモデル

```swift
@MainActor
class ExpenseViewModel: ObservableObject {
    @Published var expenses: [ExpenseWithId] = []
    @Published var genres: [GenreWithId] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let client: ShishutsukanClient
    
    init() {
        // 実際のAPIのURLに置き換えてください
        self.client = try! ShishutsukanClient(
            baseURLString: "http://localhost:8000"
        )
    }
    
    func loadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let expensesTask = client.getExpenses()
            async let genresTask = client.getGenres()
            
            (expenses, genres) = try await (expensesTask, genresTask)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadExpenses() async {
        do {
            expenses = try await client.getExpenses()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func addExpense(date: String, genre: String, amount: Int) async {
        let expense = Expense(date: date, genre: genre, amount: amount)
        
        do {
            _ = try await client.addExpense(expense)
            await loadExpenses()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func deleteExpense(id: Int) async {
        do {
            _ = try await client.deleteExpense(id: id)
            await loadExpenses()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

### 支出リストビュー

```swift
struct ExpenseListView: View {
    @ObservedObject var viewModel: ExpenseViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.expenses) { expense in
                HStack {
                    VStack(alignment: .leading) {
                        Text(expense.genre)
                            .font(.headline)
                        Text(expense.date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("¥\(expense.amount)")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .swipeActions {
                    Button(role: .destructive) {
                        Task {
                            await viewModel.deleteExpense(id: expense.id)
                        }
                    } label: {
                        Label("削除", systemImage: "trash")
                    }
                }
            }
        }
    }
}
```

### 支出追加フォーム

```swift
struct ExpenseFormView: View {
    @ObservedObject var viewModel: ExpenseViewModel
    @State private var selectedDate = Date()
    @State private var selectedGenre = "食費"
    @State private var amount = ""
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
    
    var body: some View {
        Form {
            Section("新規支出") {
                DatePicker("日付", selection: $selectedDate, displayedComponents: .date)
                
                Picker("ジャンル", selection: $selectedGenre) {
                    ForEach(viewModel.genres) { genre in
                        Text(genre.name).tag(genre.name)
                    }
                }
                
                TextField("金額", text: $amount)
                    .keyboardType(.numberPad)
                
                Button("追加") {
                    guard let amountValue = Int(amount) else { return }
                    
                    Task {
                        await viewModel.addExpense(
                            date: dateFormatter.string(from: selectedDate),
                            genre: selectedGenre,
                            amount: amountValue
                        )
                        amount = ""
                    }
                }
                .disabled(amount.isEmpty)
            }
        }
        .frame(height: 250)
    }
}
```

## バックグラウンド同期の実装

```swift
class ExpenseSyncManager {
    private let client: ShishutsukanClient
    private var syncTimer: Timer?
    
    init(client: ShishutsukanClient) {
        self.client = client
    }
    
    func startAutoSync(interval: TimeInterval = 300) { // 5分ごと
        syncTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task {
                await self?.syncExpenses()
            }
        }
    }
    
    func stopAutoSync() {
        syncTimer?.invalidate()
        syncTimer = nil
    }
    
    private func syncExpenses() async {
        do {
            let expenses = try await client.getExpenses()
            // ローカルデータベースと同期する処理
            print("同期完了: \(expenses.count)件")
        } catch {
            print("同期エラー: \(error)")
        }
    }
}
```

## エラーハンドリングのベストプラクティス

```swift
func handleExpenseOperation() async {
    do {
        let expenses = try await client.getExpenses()
        // 正常処理
    } catch ShishutsukanError.invalidURL {
        // URLが無効
        showAlert("設定エラー", "APIのURLが正しく設定されていません")
    } catch ShishutsukanError.httpError(let statusCode) {
        // HTTPエラー
        switch statusCode {
        case 404:
            showAlert("エラー", "リソースが見つかりません")
        case 500...599:
            showAlert("サーバーエラー", "サーバーに問題が発生しています")
        default:
            showAlert("エラー", "通信エラーが発生しました (HTTP \(statusCode))")
        }
    } catch ShishutsukanError.serverError(let message) {
        // サーバー側のビジネスロジックエラー
        showAlert("エラー", message)
    } catch {
        // その他のエラー
        showAlert("エラー", "予期しないエラーが発生しました")
    }
}

func showAlert(_ title: String, _ message: String) {
    // アラート表示処理
    print("\(title): \(message)")
}
```

## テスト用のモックClient

```swift
// テスト用のプロトコル
protocol ExpenseClientProtocol {
    func getExpenses() async throws -> [ExpenseWithId]
    func addExpense(_ expense: Expense) async throws -> APIMessage
    func deleteExpense(id: Int) async throws -> APIMessage
}

// ShishutsukanClientを拡張
extension ShishutsukanClient: ExpenseClientProtocol {}

// モッククライアント
class MockExpenseClient: ExpenseClientProtocol {
    var mockExpenses: [ExpenseWithId] = []
    
    func getExpenses() async throws -> [ExpenseWithId] {
        return mockExpenses
    }
    
    func addExpense(_ expense: Expense) async throws -> APIMessage {
        let newId = (mockExpenses.map { $0.id }.max() ?? 0) + 1
        let newExpense = ExpenseWithId(
            id: newId,
            date: expense.date,
            genre: expense.genre,
            amount: expense.amount
        )
        mockExpenses.append(newExpense)
        return APIMessage(message: "ok")
    }
    
    func deleteExpense(id: Int) async throws -> APIMessage {
        mockExpenses.removeAll { $0.id == id }
        return APIMessage(message: "deleted")
    }
}
```

これらの例を参考に、あなたのプロジェクトに合わせてカスタマイズしてください！
