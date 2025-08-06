#!/bin/bash

SVG_INPUT_DIR="/data/input/svg"
PNG_INPUT_DIR="/data/input/png"
PNG_TEMP_DIR="/tmp/png_icons"
OUTPUT_DIR="/data/output"
SPRITE_NAME="sprite"
NODE_SCRIPT_PATH="/app/generate_sprite.js"

mkdir -p "${PNG_TEMP_DIR}" "${OUTPUT_DIR}"

echo "1) SVG → PNG + PNG@2x"
SVG_FILES=$(find "${SVG_INPUT_DIR}" -name "*.svg")
if [ -n "${SVG_FILES}" ]; then
  for SVG in ${SVG_FILES}; do
    NAME=$(basename "${SVG}" .svg)
    OUT1X="${PNG_TEMP_DIR}/${NAME}.png"
    OUT2X="${PNG_TEMP_DIR}/${NAME}@2x.png"

    # ファイル名衝突回避（PNG由来と同名なら -svg を追加）
    if [ -e "${OUT1X}" ] || [ -e "${OUT2X}" ]; then
      NAME="${NAME}-svg"
      OUT1X="${PNG_TEMP_DIR}/${NAME}.png"
      OUT2X="${PNG_TEMP_DIR}/${NAME}@2x.png"
      echo "⚠️ 衝突回避のためファイル名に -svg を付加: ${NAME}"
    fi

    # 通常解像度 (48px, dpi=96)
    inkscape "${SVG}" \
      --export-type=png \
      --export-filename="${OUT1X}" \
      --export-background-opacity=0 \
      --export-dpi=96

    # 高解像度 (96px, dpi=192)
    inkscape "${SVG}" \
      --export-type=png \
      --export-filename="${OUT2X}" \
      --export-background-opacity=0 \
      --export-dpi=192

    if [ $? -ne 0 ]; then
      echo "Error: ${SVG} の変換に失敗"; exit 1
    fi
    echo "  → ${OUT1X} / ${OUT2X}"
  done
else
  echo "SVG が見つかりませんでした（スキップ）"
fi

echo "2) PNGを入力 → PNG + PNG@2x"
PNG_FILES=$(find "${PNG_INPUT_DIR}" -name "*.png")
if [ -n "${PNG_FILES}" ]; then
  for PNG in ${PNG_FILES}; do
    NAME=$(basename "${PNG}" .png)
    OUT1X="${PNG_TEMP_DIR}/${NAME}.png"
    OUT2X="${PNG_TEMP_DIR}/${NAME}@2x.png"

    # 2x はそのままコピー
    cp "${PNG}" "${OUT2X}"

    # 1x は50%に縮小（ImageMagick）
    convert "${PNG}" -resize 50% "${OUT1X}"

    echo "  → ${OUT1X} / ${OUT2X}"
  done
else
  echo "PNG が見つかりませんでした（スキップ）"
fi

# PNGが一つもない場合は終了
if [ -z "$(find "${PNG_TEMP_DIR}" -name '*.png')" ]; then
  echo "変換・入力されたPNGが見つかりません"; exit 1
fi

echo "3) スプライト生成 (1x + 2x)"
cat << EOF > "${NODE_SCRIPT_PATH}"
const Spritesmith = require('spritesmith');
const fs = require('fs'), path = require('path');

function generateSprite(scale) {
  const pngDir = process.env.PNG_TEMP_DIR;
  const outDir = process.env.OUTPUT_DIR;
  const name   = process.env.SPRITE_NAME;

  const suffix = scale === 2 ? '@2x' : '';
  const files = fs.readdirSync(pngDir)
    .filter(f => f.endsWith('.png') && (scale === 2 ? f.includes('@2x') : !f.includes('@2x')))
    .map(f => path.join(pngDir, f));

  Spritesmith.run({ src: files }, (err, result) => {
    if (err) throw err;

    fs.writeFileSync(path.join(outDir, name + suffix + '.png'), result.image);

    let meta = {};
    for (let file in result.coordinates) {
      const c = result.coordinates[file];
      const key = path.basename(file, '.png').replace('@2x', '');
      meta[key] = {
        x: c.x, y: c.y, width: c.width, height: c.height, pixelRatio: scale
      };
    }

    fs.writeFileSync(path.join(outDir, name + suffix + '.json'),
      JSON.stringify(meta, null, 2));
    console.log(\`Sprite\${suffix} generated.\`);
  });
}

generateSprite(1);
generateSprite(2);
EOF

export PNG_TEMP_DIR OUTPUT_DIR SPRITE_NAME
node "${NODE_SCRIPT_PATH}" || { echo "Spritesmith error"; exit 1; }

echo "4) 後処理・クリーンアップ"
rm -rf "${PNG_TEMP_DIR}" "${NODE_SCRIPT_PATH}"

echo "完了: ${OUTPUT_DIR}/${SPRITE_NAME}.{png,json,@2x.png,@2x.json}"