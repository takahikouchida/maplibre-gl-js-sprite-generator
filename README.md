# maplibre-gl-js-sprite-generator

**MapLibre GL JS 用のスプライト画像（sprite.png / sprite.json）を自動生成する CLI ツールです。**  
SVG または PNG ファイルを 1x / 2x 解像度のスプライトに変換できます。

**CLI tool to generate `sprite.png` / `sprite.json` and `sprite@2x.png` / `sprite@2x.json` for [MapLibre GL JS](https://maplibre.org/).**  
Provide SVG or PNG icons, and it automatically generates both 1x and 2x sprite assets.


---

## ✅ 特長 / Features

- 🖼️ 高解像度のアイコン画像（例: 96×96px）から 1x / 2x スプライトを生成  
  Generates 1x / 2x sprites from a single high-resolution (2x) icon image
- 🟢 SVG / PNG 両対応  
  Supports both SVG and PNG formats
- 📦 Docker で簡単に実行可能（ローカル環境の依存なし）  
  No local dependency – runs fully in Docker
- 📱 高解像度ディスプレイ対応  
  Retina/high-DPI support with `@2x` sprite generation

---

## 🚀 使い方 / Usage

### 🔨 ビルド / Build

```bash
git clone https://github.com/takahikouchida/maplibre-gl-js-sprite-generator.git
cd maplibre-gl-js-sprite-generator
docker build -t spritegen .
```

### ▶️ 実行 / Run

```bash
docker run --rm \
  -v $(pwd)/input:/data/input \
  -v $(pwd)/output:/data/output \
  spritegen
```

---

## 📁 入出力構成 / Input & Output Structure

### 📥 入力 / Input

```
input/
├── svg/
│   ├── castle.svg
│   └── gate.svg
├── png/
│   ├── tower.png   # 96x96 PNG
│   └── temple.png
```

### 📤 出力 / Output

```
output/
├── sprite.png
├── sprite.json
├── sprite@2x.png
└── sprite@2x.json
```

---

## ⚙️ カスタマイズ / Customization

環境変数で各ディレクトリや出力ファイル名を変更できます。  
You can override paths and sprite name with environment variables.

```bash
docker run --rm \
  -v $(pwd)/my-icons:/my-icons \
  -e SVG_INPUT_DIR=/my-icons/svg \
  -e PNG_INPUT_DIR=/my-icons/png \
  -e OUTPUT_DIR=/my-icons/output \
  -e SPRITE_NAME=custom_sprite \
  spritegen
```

---

## 📌 補足 / Notes

- `icon.png` → 1x 用、`icon@2x.png` → 2x 用に分類されます  
  `icon.png` is used for 1x, `icon@2x.png` is used for 2x
- 出力 JSON には `pixelRatio` フィールドが付加されます  
  Output JSON includes `pixelRatio` (1 or 2)

---

---

## ⚠️ 注意 / Note on filename collisions

SVG と PNG に同じ名前のファイル（例: `castle.svg` と `castle.png`）が存在する場合、  
ファイル名の衝突を避けるため、SVG 由来の出力ファイルには自動的に `-svg` サフィックスが追加されます。

When both an SVG and a PNG file share the same base filename (e.g., `castle.svg` and `castle.png`),  
the script automatically appends a `-svg` suffix to the PNG output derived from the SVG in order to prevent overwriting.

### 例 / Example

```
Input:
  svg/castle.svg
  png/castle.png

Output:
  castle.png         # ← from PNG
  castle@2x.png      # ← from PNG
  castle-svg.png     # ← from SVG (renamed)
  castle-svg@2x.png  # ← from SVG (renamed)
```

この処理により、すべてのファイルが安全にスプライトに含まれます。  
This ensures that all assets are preserved and included in the sprite safely.

## 📄 ライセンス / License

MIT License  
