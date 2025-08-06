# maplibre-gl-js-sprite-generator

**MapLibre GL JS 用のスプライト画像（sprite.png / sprite.json）を自動生成する CLI ツールです。**  
96×96 px の SVG または PNG ファイルを 1x / 2x 解像度のスプライトに変換できます。

**CLI tool to generate `sprite.png` / `sprite.json` and `sprite@2x.png` / `sprite@2x.json` for [MapLibre GL JS](https://maplibre.org/).**  
Provide only 96×96 px SVG or PNG icons, and it automatically generates both 1x and 2x sprite assets.


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
docker build -t maplibre-gl-js-sprite-generator .
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

- 入力ファイルは **96×96 px** に統一してください（1x は自動で半分に縮小）  
  Input icons must be 96×96 px. 1x icons are generated automatically by downscaling.
- `icon.png` → 1x 用、`icon@2x.png` → 2x 用に分類されます  
  `icon.png` is used for 1x, `icon@2x.png` is used for 2x
- 出力 JSON には `pixelRatio` フィールドが付加されます  
  Output JSON includes `pixelRatio` (1 or 2)

---

## 📄 ライセンス / License

MIT License  
© 2025 Your Name