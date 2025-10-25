# LiveMatch 

## 📋 目錄

- [功能特色](#功能特色)
- [技術架構](#技術架構)
- [架構說明](#架構說明)
- [專案結構](#專案結構)
- [開始使用](#開始使用)
- [測試](#測試)
- [性能優化](#性能優化)

## 功能特色

- ⚡️ **即時賠率更新**：模擬每秒最多 10 次的賠率更新
- 🎯 **高效能 UI**：使用 `UITableViewDiffableDataSource` 實現增量更新
- 📊 **性能監控**：追蹤更新次數、延遲和記憶體使用
- 🔒 **執行緒安全**：使用 Swift Actor 確保資料一致性
- 🧪 **完整測試**：包含單元測試和 UI 測試
- 🎨 **流暢動畫**：賠率變化時的視覺回饋

## 技術架構

本專案採用 **MVVM (Model-View-ViewModel)** 架構模式，結合以下技術：

- **Swift Concurrency** (async/await, Actor)
- **Combine Framework**
- **UIKit** with `DiffableDataSource`
- **Protocol-Oriented Programming**
- **XCTest** for Unit Testing

### 系統架構圖

```
┌─────────────────────────────────────────────────────────────┐
│                         View Layer                          │
│  ┌────────────────────┐         ┌────────────────────────┐ │
│  │ MatchViewController│◄────────┤   MatchInfoCell        │ │
│  └────────┬───────────┘         └────────────────────────┘ │
│           │ Input/Output                                     │
│           ▼                                                  │
│  ┌─────────────────────────────────────────────────────┐   │
│  │            MatchesViewModel                          │   │
│  │  • Transform Input to Output                         │   │
│  │  • Debounce Updates (150ms)                          │   │
│  └─────────┬───────────────────────────────────────────┘   │
└────────────┼─────────────────────────────────────────────────┘
             │ async/await + Combine
             ▼
┌─────────────────────────────────────────────────────────────┐
│                   Data Layer (Actor)                         │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              MatchesStore (Actor)                    │   │
│  │  • Thread-Safe Data Storage                          │   │
│  │  • Publish Updates via Combine                       │   │
│  └─────────┬───────────────────────────────────────────┘   │
│            │ Updates                                          │
│            ▼                                                  │
│  ┌─────────────────────────────────────────────────────┐   │
│  │         WebSocketSimulator                           │   │
│  │  • Simulate Real-time Updates (10/sec)               │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## 架構說明

### 1. Swift Concurrency / Combine 使用場景

#### Swift Concurrency (async/await, Actor)

**使用場景：**
- **資料存取層**：`MatchesStore` 使用 `actor` 確保執行緒安全
- **API 呼叫**：使用 `async/await` 處理非同步網路請求
- **資料初始化**：使用 `Task` 處理非同步初始化流程

#### Combine Framework

**使用場景：**
- **資料流管理**：使用 `PassthroughSubject` 和 `AnyPublisher` 發布資料更新
- **UI 綁定**：使用 `@Published` 屬性包裝器實現響應式 UI
- **防抖處理**：使用 `debounce` 操作符減少 UI 更新頻率（150ms）
- **執行緒切換**：使用 `receive(on:)` 確保 UI 更新在主執行緒

#### 為什麼混用兩種技術？

| 技術 | 使用場景 | 優勢 |
|------|---------|------|
| **Swift Concurrency** | 資料存取、API 呼叫 | 執行緒安全、清晰的非同步程式碼 |
| **Combine** | 資料流、UI 綁定 | 強大的操作符、與 UIKit 整合 |

### 2. Thread-Safe 資料存取

#### 使用 Swift Actor 確保執行緒安全

`MatchesStore` 使用 `actor` 關鍵字，提供以下保證：

**Actor 的優勢：**
- ✅ **自動序列化存取**：同一時間只有一個任務可以修改資料
- ✅ **編譯時檢查**：防止資料競爭（Data Race）
- ✅ **無需手動鎖定**：比傳統的 `DispatchQueue` 或 `NSLock` 更安全且易用

### 3. UI 與 ViewModel 資料綁定

#### Input-Output Pattern

採用單向資料流的 Input-Output 模式：

- **Input**：來自 View 的事件（生命週期、用戶操作）
- **Output**：傳遞給 View 的狀態（`@Published` 屬性）
- **Transform**：將 Input 轉換為 Output 的邏輯

#### Combine 響應式綁定

**資料流向：**

1. **ViewModel** 訂閱 Store 的更新
2. 使用 `receive(on:)` 切換到主執行緒
3. 使用 `debounce` 減少更新頻率
4. 更新 `@Published` 屬性
5. **ViewController** 監聽 `@Published` 屬性變化
6. 觸發 UI 更新

#### 高效能 UI 更新

使用 `UITableViewDiffableDataSource` 實現增量更新：

**優勢：**
- ✅ **自動差異計算**：只更新變化的 cell
- ✅ **流暢動畫**：自動處理插入、刪除、移動
- ✅ **避免閃爍**：不需要 `reloadData()`
- ✅ **性能優化**：減少不必要的 UI 重繪

#### 完整資料流

```
User Action
    ↓
Input Event (Combine Subject)
    ↓
ViewModel.transform()
    ↓
MatchesStore (Actor) - async/await
    ↓
Combine Publisher
    ↓
ViewModel @Published Property
    ↓
ViewController Subscription
    ↓
DiffableDataSource.apply()
    ↓
UI Update Complete
```

## 專案結構

```
LiveMatch/
├── MatchesModule/
│   ├── API/                    # API 模擬層
│   ├── Controller/             # 視圖控制器
│   ├── Model/                  # 資料模型
│   ├── Performance/            # 性能監控
│   ├── Protocols/              # 協議定義
│   ├── Socket/                 # WebSocket 模擬
│   ├── ViewModel/              # ViewModel 與 Store
│   └── Views/                  # 自定義 View
├── AppDelegate.swift
└── SceneDelegate.swift

LiveMatchTests/
├── Mocks/                      # Mock 物件
├── MatchesViewModelTests.swift # ViewModel 測試
└── LiveMatchTests.swift
```

## 開始使用

### 前置需求

- Xcode 16.0+
- iOS 18.2+
- Swift 5.9+

### 測試覆蓋

- ✅ ViewModel 生命週期測試
- ✅ 資料更新流程測試
- ✅ Metrics 追蹤測試
- ✅ UI 更新計數測試
- ✅ 多次更新歷史記錄測試

## 性能優化

### 關鍵優化技術

1. **防抖機制 (Debounce)**
   - 將高頻率更新（10次/秒）降低到約 6-7 次/秒
   - 減少 UI 重繪次數

2. **DiffableDataSource**
   - 只更新變化的 cell
   - 自動處理動畫
   - 避免全表刷新

3. **Actor 隔離**
   - 消除資料競爭
   - 自動序列化存取
   - 無鎖定開銷

### 性能指標追蹤

應用程式追蹤以下指標：

- 📊 **接收更新數**：WebSocket 推送的總更新數
- 🎨 **UI 更新數**：實際觸發的 UI 更新次數
- ⏱️ **平均延遲**：從接收更新到 UI 更新的時間

## 技術

- **語言**: Swift 5.9+
- **最低部署版本**: iOS 18.2
- **架構模式**: MVVM
- **並發**: Swift Concurrency (Actor, async/await)
- **響應式**: Combine Framework
- **UI**: UIKit with DiffableDataSource
- **測試**: XCTest

## 授權

MIT License

## 作者

Boray Chen

---

**注意**: 這是一個展示專案，用於演示 Swift 現代並發編程和響應式編程的最佳實踐。WebSocket 連接和 API 呼叫都是模擬的。

