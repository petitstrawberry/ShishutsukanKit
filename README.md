# ShishutsukanKit

**ShishutsukanKit**は、[sfujibijutsukan/shishutsukan](https://github.com/sfujibijutsukan/shishutsukan) の支出管理WebアプリケーションのAPIクライアントライブラリです。

## 特徴

- ✅ Swift純正機能のみを使用（URLSession）
- ✅ Async/Await対応
- ✅ マルチプラットフォーム対応（iOS 15+、macOS 12+、tvOS 15+、watchOS 8+）
- ✅ 型安全なAPIインターフェース
- ✅ エラーハンドリング

## インストール

### Swift Package Manager

`Package.swift` に以下を追加してください：

```swift
dependencies: [
    .package(url: "https://github.com/petitstrawberry/ShishutsukanKit.git", from: "1.0.0")
]
```

または、Xcodeで以下の手順で追加できます：
1. File > Add Package Dependencies...
2. リポジトリURL `https://github.com/petitstrawberry/ShishutsukanKit.git` を入力
3. バージョンを選択して追加

## 使い方

### 基本的な初期化

```swift
import ShishutsukanKit

// URLから初期化
let baseURL = URL(string: "http://localhost:8000")!
let client = ShishutsukanClient(baseURL: baseURL)

// または文字列から初期化
let client = try ShishutsukanClient(baseURLString: "http://localhost:8000")
```

### 支出データの操作

#### 支出データの追加

```swift
let expense = Expense(date: "2025-01-15", genre: "食費", amount: 1000)
let result = try await client.addExpense(expense)
print(result.message ?? "登録完了")
```

#### 支出データの取得

```swift
let expenses = try await client.getExpenses()
for expense in expenses {
    print("\(expense.date): \(expense.genre) - ¥\(expense.amount)")
}
```

#### 支出データの削除

```swift
let expenseId = 1
let result = try await client.deleteExpense(id: expenseId)
print(result.message ?? "削除完了")
```

### ジャンルの操作

#### ジャンル一覧の取得

```swift
let genres = try await client.getGenres()
for genre in genres {
    print("\(genre.id): \(genre.name)")
}
```

#### ジャンルの追加

```swift
let newGenre = Genre(name: "娯楽費")
let result = try await client.addGenre(newGenre)
print(result.message ?? "追加完了")
```

#### ジャンルの削除

```swift
let genreId = 7
let result = try await client.deleteGenre(id: genreId)
print(result.message ?? "削除完了")
```

### エラーハンドリング

```swift
do {
    let expenses = try await client.getExpenses()
    // 処理
} catch ShishutsukanError.invalidURL {
    print("無効なURLです")
} catch ShishutsukanError.httpError(let statusCode) {
    print("HTTPエラー: \(statusCode)")
} catch ShishutsukanError.serverError(let message) {
    print("サーバーエラー: \(message)")
} catch {
    print("その他のエラー: \(error)")
}
```

## API仕様

### 支出管理

| メソッド | 説明 | 戻り値 |
|---------|------|--------|
| `addExpense(_:)` | 支出データを追加 | `APIMessage` |
| `getExpenses()` | 支出データ一覧を取得 | `[ExpenseWithId]` |
| `deleteExpense(id:)` | 支出データを削除 | `APIMessage` |

### ジャンル管理

| メソッド | 説明 | 戻り値 |
|---------|------|--------|
| `getGenres()` | ジャンル一覧を取得 | `[GenreWithId]` |
| `addGenre(_:)` | ジャンルを追加 | `APIMessage` |
| `deleteGenre(id:)` | ジャンルを削除 | `APIMessage` |

## データモデル

### Expense
```swift
public struct Expense: Codable, Sendable {
    public let date: String    // 日付（例: "2025-01-15"）
    public let genre: String   // ジャンル
    public let amount: Int     // 金額
}
```

### ExpenseWithId
```swift
public struct ExpenseWithId: Codable, Sendable, Identifiable {
    public let id: Int         // ID
    public let date: String    // 日付
    public let genre: String   // ジャンル
    public let amount: Int     // 金額
}
```

### Genre
```swift
public struct Genre: Codable, Sendable {
    public let name: String    // ジャンル名
}
```

### GenreWithId
```swift
public struct GenreWithId: Codable, Sendable, Identifiable {
    public let id: Int              // ID
    public let name: String         // ジャンル名
    public let createdAt: String    // 作成日時
}
```

## SwiftUIでの使用例

```swift
import SwiftUI
import ShishutsukanKit

struct ExpenseListView: View {
    @State private var expenses: [ExpenseWithId] = []
    private let client: ShishutsukanClient
    
    init() {
        self.client = try! ShishutsukanClient(baseURLString: "http://localhost:8000")
    }
    
    var body: some View {
        List(expenses) { expense in
            HStack {
                Text(expense.date)
                Spacer()
                Text(expense.genre)
                Text("¥\(expense.amount)")
            }
        }
        .task {
            await loadExpenses()
        }
    }
    
    func loadExpenses() async {
        do {
            expenses = try await client.getExpenses()
        } catch {
            print("エラー: \(error)")
        }
    }
}
```

## 設計思想

### アーキテクチャ

ShishutsukanKitは以下の設計原則に従っています：

1. **依存ライブラリゼロ**: Swift標準ライブラリとFoundationのみを使用
2. **Actor-based設計**: `ShishutsukanClient`をactorとして実装し、スレッドセーフを保証
3. **Async/Await**: 非同期処理にはSwiftのネイティブな async/await を使用
4. **型安全**: すべてのAPIレスポンスを適切な型にマッピング
5. **エラーハンドリング**: 明示的なエラー型による堅牢なエラー処理

### ファイル構成

```
Sources/ShishutsukanKit/
├── ShishutsukanKit.swift       # モジュールエントリポイント
├── ShishutsukanClient.swift    # メインAPIクライアント
├── Models.swift                # データモデル定義
└── ShishutsukanError.swift     # エラー型定義
```

### URLSessionの選択理由

Alamofireなどのサードパーティライブラリを使用せず、URLSessionを選択した理由：

- **軽量**: 追加の依存関係なし
- **信頼性**: Appleの公式APIで安定性が高い
- **async/await対応**: iOS 15+で標準サポート
- **メンテナンス**: 外部ライブラリのバージョン管理が不要

## 動作要件

- iOS 15.0+
- macOS 12.0+
- tvOS 15.0+
- watchOS 8.0+
- Swift 5.9+

## テスト

```bash
swift test
```

## ライセンス

MIT License

Copyright (c) 2025 petitstrawberry

## 関連リンク

- [Shishutsukan WebアプリケーションRepos](https://github.com/sfujibijutsukan/shishutsukan)
- [API仕様](https://github.com/sfujibijutsukan/shishutsukan#api%E4%BB%95%E6%A7%98fastapi)

## 貢献

バグ報告や機能要望は [Issues](https://github.com/petitstrawberry/ShishutsukanKit/issues) からお願いします。
