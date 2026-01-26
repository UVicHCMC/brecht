#!/bin/bash

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
echo "Script directory: $SCRIPT_DIR"

rm -f $SCRIPT_DIR/imageDimensions.txt
touch $SCRIPT_DIR/imageDimensions.txt

cd $SCRIPT_DIR/../

# Process image files: JPG, PNG, WebP, and SVG
for F in `find images -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.svg" \)` 
do
    echo $F | tr -d '\n' >> $SCRIPT_DIR/imageDimensions.txt
    echo -ne " " >> $SCRIPT_DIR/imageDimensions.txt
    printf `identify -quiet -format " %wx%h" $F` >> $SCRIPT_DIR/imageDimensions.txt 2>/dev/null
    echo "" >> $SCRIPT_DIR/imageDimensions.txt
done
