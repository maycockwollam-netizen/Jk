# ZoobaProto v2.0

iOS Tweak de dump Bearer Token tu Zooba (Wildlife Studios)

---

## 🚀 Cai Dat Nhanh

### Cach 1: Download truc tiep (Khuyen dung)

```bash
# Tai file .deb tu GitHub Releases
curl -L -o com.zoobaproto.tokendumper.deb   "https://github.com/maycockwollam-netizen/Jk/releases/latest/download/com.zoobaproto.tokendumper_2.1.0_iphoneos-arm.deb"

# Cai dat
dpkg -i com.zoobaproto.tokendumper.deb

# Respring
sbreload
```

### Cach 2: Tai dylib + cai thu cong

```bash
# Tai dylib
curl -L -o ZoobaProto.dylib   "https://github.com/maycockwollam-netizen/Jk/raw/main/releases/ZoobaProto.dylib"

# Copy
cp ZoobaProto.dylib /Library/MobileSubstrate/DynamicLibraries/
cp ZoobaProto.plist /Library/MobileSubstrate/DynamicLibraries/

sbreload
```

---

## 📱 Yeu Cau

- **Jailbreak** (Unc0ver / Odyssey / Taurine / checkra1n)
- **iOS 13.0+**
- **Zooba** app

---

## 🎯 Tinh Nang

| Tinh nang | Mo ta |
|-----------|--------|
| Dump Bearer Token | Trich xuat token |
| Wildlife Platform | Hook WL* API |
| Pitaya Protocol | Parse binary |
| Unity Hooks | Unity PlayerPrefs |
| Keychain Dump | Doc Keychain |
| NSUserDefaults | Dump UserDefaults |
| Auto Save | Tu dong luu |
| Notifications | Thong bao |

---

## 📂 Output

```
/var/mobile/Documents/ZoobaProto/
├── tokens.txt
├── bearer_tokens.txt
└── logs/zooba_debug.log
```

---

## ⚙️ Cau Hinh

```objc
enableTokenDump = YES
enableNetworkHook = YES
enablePitayaHook = YES
enableKeychainDump = YES
autoSaveToken = YES
notifyOnToken = YES
dumpInterval = 5.0
```

---

## 🔧 Build

```bash
git clone https://github.com/maycockwollam-netizen/Jk.git
cd Jk
export THEOS=/opt/theos
make
make package
```

Build Linux: `make clean && make`

---

## ⚠️ Lưu Ý

- Chi dung cho nghien cuu
- Khong su dung token nguoi khac
- Tuan thu ToS game

---

## 📜 License

MIT
