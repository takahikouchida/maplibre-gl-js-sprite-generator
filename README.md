# maplibre-gl-js-sprite-generator

MapLibre GL JS / MapLibre GL 用のスプライト画像を生成する Docker ベースの CLI ツールです。

SVG または PNG のアイコン画像から、以下のファイルを自動生成します。

```text
sprite.png
sprite.json
sprite@2x.png
sprite@2x.json
````

## 特長

* SVG / PNG の両方に対応
* 1x / 2x のスプライトを自動生成
* Docker Compose で実行可能
* ローカル環境に Node.js / Inkscape / ImageMagick を直接インストール不要
* MapLibre GL JS の `sprite` 指定で利用可能

## ディレクトリ構成

```text
maplibre-gl-js-sprite-generator/
├── Dockerfile
├── docker-compose.yml
├── generate-sprites.sh
├── input/
│   ├── svg/
│   │   └── sample.svg
│   └── png/
│       └── sample.png
└── output/
    └── .gitkeep
```

## 入力ファイルの配置

SVG アイコンは以下に配置します。

```text
input/svg/
```

PNG アイコンは以下に配置します。

```text
input/png/
```

例：

```text
input/
├── svg/
│   ├── castle.svg
│   └── station.svg
└── png/
    ├── park.png
    └── school.png
```

## 実行方法

### 初回ビルド

```bash
docker compose build
```

### スプライト生成

```bash
docker compose run --rm spritegen
```

または、ビルドも同時に行う場合は以下です。

```bash
docker compose run --rm --build spritegen
```

## 出力結果

生成結果は `output/` に出力されます。

```text
output/
├── sprite.png
├── sprite.json
├── sprite@2x.png
└── sprite@2x.json
```

## docker-compose.yml

このプロジェクトでは、以下の `docker-compose.yml` を使用します。

```yaml
services:
  spritegen:
    build:
      context: .
      dockerfile: Dockerfile
    image: maplibre-gl-js-sprite-generator:local
    container_name: maplibre-spritegen
    volumes:
      - ./input:/data/input
      - ./output:/data/output
    environment:
      SVG_INPUT_DIR: /data/input/svg
      PNG_INPUT_DIR: /data/input/png
      PNG_TEMP_DIR: /tmp/png_icons
      OUTPUT_DIR: /data/output
      SPRITE_NAME: sprite
    command: ["./generate-sprites.sh"]
```

## MapLibre GL JS での指定例

生成したファイルを Web サーバー上の `/sprites/` に配置した場合、スタイル JSON では以下のように指定します。

```json
{
  "version": 8,
  "sprite": "/sprites/sprite",
  "sources": {},
  "layers": []
}
```

MapLibre は以下を自動的に参照します。

```text
/sprites/sprite.png
/sprites/sprite.json
/sprites/sprite@2x.png
/sprites/sprite@2x.json
```

## SVG 入力について

`input/svg/` に配置した SVG は、内部で PNG に変換された上でスプライト化されます。

SVG からは以下が生成されます。

```text
icon.svg
↓
icon.png
icon@2x.png
```

## PNG 入力について

`input/png/` に配置した PNG は、2x 用画像として扱われます。

例えば `96px × 96px` の PNG を配置した場合、以下のように処理されます。

```text
icon.png
↓
icon@2x.png  # 元画像を使用
icon.png     # 50% 縮小して生成
```

そのため、PNG を入力する場合は、最終的に使いたい 1x サイズの2倍程度の画像を用意してください。

例：

```text
1xで48px表示したい場合
→ 96px × 96px のPNGを input/png/ に配置
```

## SVG と PNG のファイル名が重複する場合

SVG と PNG に同じベース名のファイルが存在する場合、衝突回避のため、SVG 由来のファイル名に `-svg` が付加されます。

例：

```text
入力:
  input/svg/castle.svg
  input/png/castle.png

内部変換後:
  castle.png
  castle@2x.png
  castle-svg.png
  castle-svg@2x.png
```

このため、両方のアイコンがスプライトに含まれます。

## 出力ファイルを削除して再生成する場合

必要に応じて、既存の出力ファイルを削除してから再生成します。

```bash
rm -f output/sprite.png output/sprite.json output/sprite@2x.png output/sprite@2x.json
docker compose run --rm spritegen
```

## よく使うコマンド

```bash
# Dockerイメージをビルド
docker compose build

# スプライト生成
docker compose run --rm spritegen

# ビルドし直してスプライト生成
docker compose run --rm --build spritegen

# 出力ファイル確認
ls -l output
```

## 注意事項

* 出力ファイル名は `sprite` 固定です。
* `input/svg/` と `input/png/` の中に対象ファイルが1つもない場合、処理はエラー終了します。
* `output/` は Docker Compose の volume でホスト側にマウントされるため、生成結果はローカルの `output/` に残ります。
* Docker Desktop など、Docker Compose が利用できる環境が必要です。

## ライセンス

MIT License
