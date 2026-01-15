# Release Skill

App Store へのリリース手順

## 使用方法

```
/release [version]
```

例: `/release 1.2.0`

## 手順

### 1. バージョン更新

```bash
# project.pbxproj の MARKETING_VERSION を更新
sed -i '' 's/MARKETING_VERSION = [^;]*;/MARKETING_VERSION = <version>;/g' iOS/speedmeter/speedmeter.xcodeproj/project.pbxproj
```

### 2. コミット & プッシュ

```bash
git add -A
git commit -m "バージョン<version>に更新"
git push origin main
```

### 3. メタデータアップロード

```bash
cd /Users/entaku/repository/speedmeter
source fastlane/.env.default
fastlane upload_metadata_only
```

### 4. アーカイブ

```bash
cd /Users/entaku/repository/speedmeter/iOS/speedmeter
xcodebuild -project speedmeter.xcodeproj -scheme speedmeter -configuration Release -archivePath ./build/speedmeter.xcarchive archive
```

### 5. App Store Connect へアップロード

```bash
xcodebuild -exportArchive -archivePath ./build/speedmeter.xcarchive -exportOptionsPlist ./build/ExportOptions.plist -exportPath ./build/export -allowProvisioningUpdates
```

### 6. タグ作成（オプション）

```bash
git tag v<version>
git push origin v<version>
```

## メタデータファイル

- `fastlane/metadata/en-US/` - 英語
- `fastlane/metadata/ja/` - 日本語

## 注意事項

- App Store Connect でビルド処理完了後に審査提出可能
- dSYM の警告は Firebase/AdMob 関連で審査に影響なし
