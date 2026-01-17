#!/bin/bash

# App Store Screenshots Script
# UIテストを実行してスクリーンショットを自動撮影
#
# Usage:
#   ./scripts/take_screenshots.sh                    # 全言語・全デバイス
#   ./scripts/take_screenshots.sh en                 # 英語のみ
#   ./scripts/take_screenshots.sh ja                 # 日本語のみ
#   ./scripts/take_screenshots.sh en "iPhone 14 Pro" # 英語・指定デバイス

set -e

LANGUAGE=${1:-"all"}
DEVICE=${2:-"iPhone 14 Pro Max"}
PROJECT="iOS/speedmeter/speedmeter.xcodeproj"
SCHEME="speedmeter"

echo "📱 App Store Screenshot Automation"
echo "=================================="
echo "Language: $LANGUAGE"
echo "Device: $DEVICE"
echo ""

# 出力ディレクトリ
OUTPUT_DIR="fastlane/screenshots"
mkdir -p "$OUTPUT_DIR/en" "$OUTPUT_DIR/ja"

run_test() {
    local test_name=$1
    local lang=$2

    echo "🧪 Running: $test_name"

    xcodebuild test \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "platform=iOS Simulator,name=$DEVICE" \
        -only-testing:"speedmeterUITests/ScreenshotTests/$test_name" \
        -resultBundlePath "build/TestResults_${lang}.xcresult" \
        2>&1 | grep -E '(Test Case|passed|failed|Screenshot saved|✅)' || true

    echo ""
}

# スクショをresultBundleから抽出
extract_screenshots() {
    local lang=$1
    local result_bundle="build/TestResults_${lang}.xcresult"

    if [ -d "$result_bundle" ]; then
        echo "📁 Extracting screenshots from $result_bundle..."

        # xcresulttoolでAttachmentsを抽出
        xcrun xcresulttool get --path "$result_bundle" --format json 2>/dev/null | \
            python3 -c "
import json
import sys
import subprocess
import os

data = json.load(sys.stdin)

def find_attachments(obj, path=''):
    if isinstance(obj, dict):
        if obj.get('_type', {}).get('_name') == 'ActionTestAttachment':
            name = obj.get('name', {}).get('_value', 'unknown')
            if 'payloadRef' in obj:
                ref_id = obj['payloadRef']['id']['_value']
                print(f'{name}|{ref_id}')
        for k, v in obj.items():
            find_attachments(v, f'{path}.{k}')
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            find_attachments(v, f'{path}[{i}]')

find_attachments(data)
" | while IFS='|' read -r name ref_id; do
            if [[ "$name" == *"_${lang}"* ]]; then
                output_file="$OUTPUT_DIR/$lang/${name}.png"
                xcrun xcresulttool get --path "$result_bundle" --id "$ref_id" > "$output_file" 2>/dev/null || true
                if [ -f "$output_file" ] && [ -s "$output_file" ]; then
                    echo "  ✅ $output_file"
                fi
            fi
        done
    fi
}

# メイン処理
if [ "$LANGUAGE" = "all" ] || [ "$LANGUAGE" = "en" ]; then
    run_test "testTakeEnglishScreenshots" "en"
    extract_screenshots "en"
fi

if [ "$LANGUAGE" = "all" ] || [ "$LANGUAGE" = "ja" ]; then
    run_test "testTakeJapaneseScreenshots" "ja"
    extract_screenshots "ja"
fi

echo ""
echo "✅ Screenshots completed!"
echo "📁 Output: $OUTPUT_DIR"
ls -la "$OUTPUT_DIR/en" "$OUTPUT_DIR/ja" 2>/dev/null || true
