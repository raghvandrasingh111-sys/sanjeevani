# Fix: macOS Build Failed (CodeSign / resource fork)

Error: **resource fork, Finder information, or similar detritus not allowed**  
Cause: Extended attributes (e.g. from copying files or Finder) make code signing reject the app.

---

## Fix (run in Terminal)

**1. Go to the project folder**
```bash
cd ~/Documents/FlutterDev/Sanjeevni
```

**2. Remove extended attributes from the whole project**
```bash
xattr -cr .
```

**3. Clean and rebuild**
```bash
flutter clean
flutter pub get
flutter run -d macos
```

---

## If it still fails

**Option A – Clean only the macOS build**
```bash
cd ~/Documents/FlutterDev/Sanjeevni
rm -rf build/macos
xattr -cr macos
flutter run -d macos
```

**Option B – Run on Chrome instead of macOS**
```bash
flutter run -d chrome
```

**Option C – Disable code signing for local debug (temporary)**  
- Open `macos/Runner.xcodeproj` in Xcode  
- Select **Runner** → **Signing & Capabilities**  
- Uncheck **Automatically manage signing** (or use a development team only for real devices)  
- For “Run” scheme, confirm the build is Debug; code signing is often more relaxed

---

The **Run Script** message is a warning only; the real failure is code signing due to extended attributes. Step 2 (`xattr -cr .`) usually fixes it.
