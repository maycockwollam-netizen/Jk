# ZoobaProto v2.0

iOS Tweak để dump Bearer Token từ Zooba (Wildlife Studios)

## 🎯 Mục đích

Extract Bearer tokens từ:
- Wildlife Platform (WL*)
- Pitaya Binary Protocol
- Unity PlayerPrefs
- NSUserDefaults
- Keychain

## 📁 Cấu trúc dự án

```
ZoobaProto/
├── Makefile                    # Build configuration
├── control                     # Package info
├── project.yml                 # Project config
│
├── src/
│   ├── main.mm                 # Entry point
│   │
│   ├── config/
│   │   ├── Config.h           # Configuration
│   │   └── Config.mm
│   │
│   ├── modules/
│   │   ├── core/
│   │   │   ├── CoreModule.h   # Module manager
│   │   │   └── CoreModule.mm
│   │   │
│   │   ├── storage/
│   │   │   ├── StorageModule.h  # Token storage
│   │   │   └── StorageModule.mm
│   │   │
│   │   ├── network/
│   │   │   ├── NetworkModule.h  # Network monitoring
│   │   │   └── NetworkModule.mm
│   │   │
│   │   └── utils/
│   │       ├── UtilsModule.h     # Utilities
│   │       └── UtilsModule.mm
│   │
│   └── hooks/
│       ├── WildlifeHooks.h       # Wildlife hooks
│       ├── WildlifeHooks.mm
│       ├── UnityHooks.h         # Unity hooks
│       └── UnityHooks.mm
│
├── scripts/                    # Build scripts
├── resources/                  # Resources
├── docs/                       # Documentation
└── tests/                     # Tests
```

## 🔧 Modules

### CoreModule
- Quản lý lifecycle của các module
- Module registration
- Dependency injection

### StorageModule
- Dump tokens từ NSUserDefaults
- Dump tokens từ Keychain
- Tìm Bearer token
- Save tokens

### NetworkModule
- Hook NSURLSession
- Hook HTTP requests/responses
- Detect tokens in headers/body

### UtilsModule
- Logging utilities
- Hex dump
- Notifications
- File operations

## 🚀 Build

```bash
# Setup
export THEOS=/opt/theos

# Build
make

# Install
make install

# View logs
make logs
```

## ⚙️ Configuration

Chỉnh sửa `src/config/Config.mm`:

```objc
// Features
enableTokenDump = YES
enableNetworkHook = YES
enablePitayaHook = YES
enableKeychainDump = YES
autoSaveToken = YES
notifyOnToken = YES

// Dump interval (seconds)
dumpInterval = 5.0
```

## 📋 Features

- ✅ Modular architecture
- ✅ Configurable features
- ✅ Auto token detection
- ✅ Auto save tokens
- ✅ Local notifications
- ✅ Periodic dump
- ✅ File logging
- ✅ Hex dump utilities

## 📝 Output

```
[ZoobaProto] ========== TOKEN DUMP ==========
[ZoobaProto] 📦 UserDefaults: wildlife_access_token = eyJ...
[ZoobaProto] 🎉 BEARER TOKEN: Bearer eyJ...
[ZoobaProto] ==========================================
```

## ⚠️ Lưu ý

- Chỉ dùng cho mục đích nghiên cứu
- Không sử dụng token của người khác
- Tuân thủ ToS của game

## 📜 License

MIT License
