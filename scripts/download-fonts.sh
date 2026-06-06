#!/bin/bash

# 下载 CanvasKit 字体 fallback 所需的字体文件
#
# 字体列表从当前 Flutter SDK 的 font_fallback_data.dart 动态解析，
# 确保与编译产物使用的引擎版本一致。不再硬编码分片编号。
#
# 包括：
# - NotoSansSC-Regular.otf：通过 pubspec.yaml 绑定的完整中文字体
# - Noto Sans SC 分片 woff2：CanvasKit fallback 按需加载的中文字体分片
# - Noto Sans JP 分片 woff2：CanvasKit fallback 按需加载的日文字体分片
# - Noto Sans KR 分片 woff2：CanvasKit fallback 按需加载的韩文字体分片
# - Roboto：英文字体（CanvasKit fallback 机制使用）
#
# CanvasKit 渲染引擎在遇到绑定字体未覆盖的字符时，会从 fontFallbackBaseUrl 按需加载
# Google Fonts 的分片 woff2 文件。embedded 模式下需要预下载这些分片到本地。

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRONTEND_DIR="$(dirname "$SCRIPT_DIR")"
FONTS_DIR="$FRONTEND_DIR/web/fonts"
PUBSPEC_FONTS_DIR="$FRONTEND_DIR/fonts"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}下载 CanvasKit 字体文件${NC}"
echo -e "${BLUE}========================================${NC}"

# ========================================
# 从 Flutter SDK 解析字体 URL 列表
# ========================================

FLUTTER_ROOT="$(flutter --no-version-check sdk-path 2>/dev/null || dirname "$(dirname "$(which flutter)")")"
FONT_DATA_FILE="$FLUTTER_ROOT/bin/cache/flutter_web_sdk/lib/_engine/engine/font_fallback_data.dart"
CANVASKIT_FONTS_FILE="$FLUTTER_ROOT/bin/cache/flutter_web_sdk/lib/_engine/engine/canvaskit/fonts.dart"

if [ ! -f "$FONT_DATA_FILE" ]; then
    echo -e "${RED}错误：找不到 Flutter SDK 的 font_fallback_data.dart${NC}"
    echo -e "${RED}路径：$FONT_DATA_FILE${NC}"
    echo -e "${YELLOW}请确保已运行 'flutter precache' 或 'flutter doctor'${NC}"
    exit 1
fi

echo -e "${BLUE}Flutter SDK:${NC} $FLUTTER_ROOT"
echo -e "${BLUE}字体数据:${NC} $FONT_DATA_FILE"
echo ""

# 从 font_fallback_data.dart 提取所有字体 URL（格式如 'notosanssc/v37/xxx.75.woff2'）
extract_font_urls() {
    local pattern="$1"
    grep "$pattern" "$FONT_DATA_FILE" | grep -oP "'[^']+'" | tr -d "'"
}

# 从 canvaskit/fonts.dart 提取 Roboto URL（去除 Dart 字符串插值前缀）
extract_roboto_url() {
    grep "fontFallbackBaseUrl" "$CANVASKIT_FONTS_FILE" 2>/dev/null | grep -oP "(?<=fontFallbackBaseUrl})[^']+" | head -1
}

# 创建目录结构
mkdir -p "$PUBSPEC_FONTS_DIR"

# ========================================
# 下载 NotoSansSC-Regular.otf（pubspec.yaml 绑定字体）
# ========================================
echo -e "${BLUE}[1/5] 下载 NotoSansSC-Regular.otf...${NC}"

NOTO_OTF_FILE="$PUBSPEC_FONTS_DIR/NotoSansSC-Regular.otf"
if [ -f "$NOTO_OTF_FILE" ]; then
    echo -e "  [跳过] NotoSansSC-Regular.otf (已存在)"
else
    NOTO_OTF_URL="https://github.com/notofonts/noto-cjk/raw/main/Sans/SubsetOTF/SC/NotoSansSC-Regular.otf"
    echo -e "  [下载] NotoSansSC-Regular.otf"
    if curl -s -f -L -o "$NOTO_OTF_FILE" "$NOTO_OTF_URL" 2>/dev/null; then
        echo -e "    ${GREEN}✓${NC} 成功"
    else
        rm -f "$NOTO_OTF_FILE"
        echo -e "    ${RED}✗${NC} 下载失败"
    fi
fi

# ========================================
# 通用字体下载函数
# ========================================
download_font_set() {
    local label="$1"
    local pattern="$2"
    local base_url="https://fonts.gstatic.com/s"

    local urls
    urls=$(extract_font_urls "$pattern")
    if [ -z "$urls" ]; then
        echo -e "  ${YELLOW}⚠${NC} 未在 font_fallback_data.dart 中找到 ${pattern} 条目，跳过"
        return
    fi

    local total=0 downloaded=0 skipped=0 failed=0

    while IFS= read -r rel_path; do
        [ -z "$rel_path" ] && continue
        total=$((total + 1))

        # 从相对路径提取目录结构（如 notosanssc/v37）
        local dir_part
        dir_part=$(dirname "$rel_path")
        local filename
        filename=$(basename "$rel_path")

        mkdir -p "$FONTS_DIR/$dir_part"
        local output_file="$FONTS_DIR/$rel_path"

        if [ -f "$output_file" ]; then
            skipped=$((skipped + 1))
        else
            local url="${base_url}/${rel_path}"
            if curl -s -f -o "$output_file" "$url" 2>/dev/null; then
                downloaded=$((downloaded + 1))
            else
                rm -f "$output_file"
                failed=$((failed + 1))
            fi
        fi
    done <<< "$urls"

    echo -e "  ${GREEN}✓${NC} ${label}: 共 ${total} 个, 新下载 ${downloaded}, 已存在 ${skipped}, 失败 ${failed}"
    if [ "$failed" -gt 0 ]; then
        echo -e "  ${YELLOW}⚠${NC} 部分分片下载失败，相关字符可能显示为方框"
    fi
}

# ========================================
# 下载 Noto Sans SC 分片 woff2
# ========================================
echo -e "${BLUE}[2/5] 下载 Noto Sans SC 分片 woff2 (CanvasKit fallback - 中文)...${NC}"
download_font_set "Noto Sans SC" "notosanssc"

# ========================================
# 下载 Noto Sans JP 分片 woff2
# ========================================
echo -e "${BLUE}[3/5] 下载 Noto Sans JP 分片 woff2 (CanvasKit fallback - 日文)...${NC}"
download_font_set "Noto Sans JP" "notosansjp"

# ========================================
# 下载 Noto Sans KR 分片 woff2
# ========================================
echo -e "${BLUE}[4/5] 下载 Noto Sans KR 分片 woff2 (CanvasKit fallback - 韩文)...${NC}"
download_font_set "Noto Sans KR" "notosanskr"

# ========================================
# 下载 Roboto 字体
# ========================================
echo -e "${BLUE}[5/5] 下载 Roboto 字体...${NC}"

ROBOTO_URL=$(extract_roboto_url)
if [ -n "$ROBOTO_URL" ]; then
    dir_part=$(dirname "$ROBOTO_URL")
    filename=$(basename "$ROBOTO_URL")
    mkdir -p "$FONTS_DIR/$dir_part"
    OUTPUT_FILE="$FONTS_DIR/$ROBOTO_URL"

    if [ -f "$OUTPUT_FILE" ]; then
        echo -e "  [跳过] $filename (已存在)"
    else
        URL="https://fonts.gstatic.com/s/$ROBOTO_URL"
        echo -e "  [下载] $filename"
        if curl -s -f -o "$OUTPUT_FILE" "$URL" 2>/dev/null; then
            echo -e "    ${GREEN}✓${NC} 成功"
        else
            rm -f "$OUTPUT_FILE"
            echo -e "    ${RED}✗${NC} 下载失败"
        fi
    fi
else
    echo -e "  ${YELLOW}⚠${NC} 未找到 Roboto URL，跳过"
fi

# ========================================
# 清理不再需要的旧字体文件
# ========================================
echo ""
echo -e "${BLUE}[清理] 移除 Flutter SDK 不再需要的旧字体文件...${NC}"

cleanup_stale_fonts() {
    local pattern="$1"
    local label="$2"

    local expected_urls
    expected_urls=$(extract_font_urls "$pattern")
    [ -z "$expected_urls" ] && return

    # 获取该字体的目录（如 notosanssc/v37）
    local font_dir
    font_dir=$(echo "$expected_urls" | head -1 | xargs dirname)
    local full_dir="$FONTS_DIR/$font_dir"
    [ ! -d "$full_dir" ] && return

    local removed=0
    while IFS= read -r -d '' file; do
        local rel_path="${file#$FONTS_DIR/}"
        if ! echo "$expected_urls" | grep -qF "$rel_path"; then
            rm -f "$file"
            removed=$((removed + 1))
        fi
    done < <(find "$full_dir" -name "*.woff2" -print0 2>/dev/null)

    if [ "$removed" -gt 0 ]; then
        echo -e "  ${GREEN}✓${NC} ${label}: 移除 ${removed} 个过期分片"
    fi
}

cleanup_stale_fonts "notosanssc" "Noto Sans SC"
cleanup_stale_fonts "notosansjp" "Noto Sans JP"
cleanup_stale_fonts "notosanskr" "Noto Sans KR"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ 字体下载完成！${NC}"
echo -e "${GREEN}========================================${NC}"
