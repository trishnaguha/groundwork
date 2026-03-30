#!/bin/bash
# find-images.sh -- Find all images in a directory
# Usage: bash find-images.sh <directory-path>

DIR="${1:-.}"

if [ ! -d "$DIR" ]; then
    echo "ERROR: Directory not found: $DIR"
    exit 1
fi

echo "=== Image Manifest ==="
echo "SEARCH_PATH: $DIR"
echo ""

COUNT=0
TOTAL_SIZE=0

echo "SIZE_BYTES | DIRECTORY | FILENAME | EXTENSION"
echo "-----------|-----------|----------|----------"

find "$DIR" -type f \( \
    -iname "*.png" \
    -o -iname "*.jpg" \
    -o -iname "*.jpeg" \
    -o -iname "*.webp" \
    -o -iname "*.gif" \
    -o -iname "*.svg" \
    -o -iname "*.bmp" \
    -o -iname "*.tiff" \
    -o -iname "*.tif" \
\) -not -path '*/.git/*' 2>/dev/null | sort | while read -r img; do
    SIZE=$(wc -c < "$img" 2>/dev/null | tr -d ' ')
    DIR_PATH=$(dirname "$img")
    NAME=$(basename "$img")
    EXT="${NAME##*.}"
    echo "$SIZE | $DIR_PATH | $NAME | $EXT"
    COUNT=$((COUNT + 1))
    TOTAL_SIZE=$((TOTAL_SIZE + SIZE))
done

echo ""
echo "=== Image Summary ==="

TOTAL_COUNT=$(find "$DIR" -type f \( \
    -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \
    -o -iname "*.webp" -o -iname "*.gif" -o -iname "*.svg" \
    -o -iname "*.bmp" -o -iname "*.tiff" -o -iname "*.tif" \
\) -not -path '*/.git/*' 2>/dev/null | wc -l | tr -d ' ')

echo "TOTAL_IMAGES: $TOTAL_COUNT"

# Count by type
for ext in png jpg jpeg svg gif webp bmp tiff; do
    TYPE_COUNT=$(find "$DIR" -type f -iname "*.$ext" -not -path '*/.git/*' 2>/dev/null | wc -l | tr -d ' ')
    if [ "$TYPE_COUNT" -gt 0 ]; then
        echo "COUNT_$ext: $TYPE_COUNT"
    fi
done

# Flag large images (>10MB)
LARGE=$(find "$DIR" -type f \( \
    -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \
    -o -iname "*.webp" -o -iname "*.gif" -o -iname "*.svg" \
\) -not -path '*/.git/*' -size +10M 2>/dev/null)

if [ -n "$LARGE" ]; then
    echo ""
    echo "=== Large Images (>10MB, will be skipped) ==="
    echo "$LARGE"
fi

echo ""
echo "=== Manifest Complete ==="
