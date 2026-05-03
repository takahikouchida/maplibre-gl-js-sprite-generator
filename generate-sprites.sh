#!/bin/bash
set -euo pipefail

SVG_INPUT_DIR="/data/input/svg"
PNG_INPUT_DIR="/data/input/png"
PNG_TEMP_DIR="/tmp/png_icons"
OUTPUT_DIR="/data/output"
SPRITE_NAME="sprite"
NODE_SCRIPT_PATH="/app/generate_sprite.js"

# 出力アイコンサイズ
# 縦横の大きい方をこのサイズにする
ICON_SIZE_1X=32
ICON_SIZE_2X=64

mkdir -p "${PNG_TEMP_DIR}" "${OUTPUT_DIR}"

make_unique_name() {
  local base_name="$1"
  local name="$base_name"
  local count=1

  while [ -e "${PNG_TEMP_DIR}/${name}.png" ] || [ -e "${PNG_TEMP_DIR}/${name}@2x.png" ]; do
    name="${base_name}-${count}"
    count=$((count + 1))
  done

  printf '%s' "$name"
}

echo "1) SVG → PNG + PNG@2x"
if [ -d "${SVG_INPUT_DIR}" ]; then
  while IFS= read -r -d '' SVG; do
    BASE_NAME="$(basename "${SVG}" .svg)"
    NAME="$(make_unique_name "${BASE_NAME}")"

    OUT1X="${PNG_TEMP_DIR}/${NAME}.png"
    OUT2X="${PNG_TEMP_DIR}/${NAME}@2x.png"

    TMP_PNG="${PNG_TEMP_DIR}/${NAME}__tmp.png"

    # いったんSVGをPNG化する
    # サイズ指定はここでは行わず、元SVGの縦横比を維持する
    inkscape "${SVG}" \
      --export-type=png \
      --export-filename="${TMP_PNG}" \
      --export-background-opacity=0

    if [ $? -ne 0 ]; then
      echo "Error: ${SVG} のSVG変換に失敗"
      exit 1
    fi

    # 1x: 縦横の大きい方を32pxにする
    # ImageMagickの -resize 32x32 は縦横比を維持し、
    # 32x32の枠内に収まる最大サイズへ変換する
    convert "${TMP_PNG}" \
      -background none \
      -resize "${ICON_SIZE_1X}x${ICON_SIZE_1X}" \
      "${OUT1X}"

    if [ $? -ne 0 ]; then
      echo "Error: ${SVG} の1xリサイズに失敗"
      exit 1
    fi

    # 2x: 縦横の大きい方を64pxにする
    convert "${TMP_PNG}" \
      -background none \
      -resize "${ICON_SIZE_2X}x${ICON_SIZE_2X}" \
      "${OUT2X}"

    if [ $? -ne 0 ]; then
      echo "Error: ${SVG} の2xリサイズに失敗"
      exit 1
    fi

    rm -f "${TMP_PNG}"

    echo "  → ${OUT1X} / ${OUT2X}"

  done < <(find "${SVG_INPUT_DIR}" -name "*.svg" -print0)
else
  echo "SVG入力ディレクトリが見つかりませんでした（スキップ）"
fi

echo "2) PNGを入力 → PNG + PNG@2x"
if [ -d "${PNG_INPUT_DIR}" ]; then
  while IFS= read -r -d '' PNG; do
    BASE_NAME="$(basename "${PNG}" .png)"
    NAME="$(make_unique_name "${BASE_NAME}")"

    OUT1X="${PNG_TEMP_DIR}/${NAME}.png"
    OUT2X="${PNG_TEMP_DIR}/${NAME}@2x.png"

    # 1x: 縦横の大きい方を32pxにする
    convert "${PNG}" \
      -background none \
      -resize "${ICON_SIZE_1X}x${ICON_SIZE_1X}" \
      "${OUT1X}"

    if [ $? -ne 0 ]; then
      echo "Error: ${PNG} の1x変換に失敗"
      exit 1
    fi

    # 2x: 縦横の大きい方を64pxにする
    convert "${PNG}" \
      -background none \
      -resize "${ICON_SIZE_2X}x${ICON_SIZE_2X}" \
      "${OUT2X}"

    if [ $? -ne 0 ]; then
      echo "Error: ${PNG} の2x変換に失敗"
      exit 1
    fi

    echo "  → ${OUT1X} / ${OUT2X}"

  done < <(find "${PNG_INPUT_DIR}" -name "*.png" -print0)
else
  echo "PNG入力ディレクトリが見つかりませんでした（スキップ）"
fi

# PNGが一つもない場合は終了
if [ -z "$(find "${PNG_TEMP_DIR}" -name '*.png' -print -quit)" ]; then
  echo "変換・入力されたPNGが見つかりません"
  exit 1
fi

echo "3) スプライト生成 (1x + 2x)"
cat << EOF > "${NODE_SCRIPT_PATH}"
const Spritesmith = require('spritesmith');
const fs = require('fs');
const path = require('path');

function generateSprite(scale) {
  const pngDir = process.env.PNG_TEMP_DIR;
  const outDir = process.env.OUTPUT_DIR;
  const name = process.env.SPRITE_NAME;

  const suffix = scale === 2 ? '@2x' : '';

  const files = fs.readdirSync(pngDir)
    .filter(f => {
      if (!f.endsWith('.png')) return false;
      if (f.includes('__tmp')) return false;
      return scale === 2 ? f.includes('@2x') : !f.includes('@2x');
    })
    .map(f => path.join(pngDir, f));

  if (files.length === 0) {
    throw new Error('No PNG files found for scale ' + scale);
  }

  Spritesmith.run({ src: files }, (err, result) => {
    if (err) throw err;

    fs.writeFileSync(path.join(outDir, name + suffix + '.png'), result.image);

    const meta = {};

    for (const file in result.coordinates) {
      const c = result.coordinates[file];
      const key = path.basename(file, '.png').replace('@2x', '');

      meta[key] = {
        x: c.x,
        y: c.y,
        width: c.width,
        height: c.height,
        pixelRatio: scale
      };
    }

    fs.writeFileSync(
      path.join(outDir, name + suffix + '.json'),
      JSON.stringify(meta, null, 2)
    );

    console.log(\`Sprite\${suffix} generated.\`);
  });
}

generateSprite(1);
generateSprite(2);
EOF

export PNG_TEMP_DIR OUTPUT_DIR SPRITE_NAME
node "${NODE_SCRIPT_PATH}" || {
  echo "Spritesmith error"
  exit 1
}

echo "4) 後処理・クリーンアップ"
rm -rf "${PNG_TEMP_DIR}" "${NODE_SCRIPT_PATH}"

echo "完了: ${OUTPUT_DIR}/${SPRITE_NAME}.{png,json,@2x.png,@2x.json}"