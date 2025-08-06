# Node.js 20 のベースイメージ
FROM node:20

# 作業ディレクトリの設定
WORKDIR /app

# 必要なツールをインストール
# - ImageMagick：PNGリサイズ
# - Inkscape：SVG → PNG変換
RUN apt-get update && apt-get install -y --no-install-recommends \
    imagemagick \
    inkscape \
    librsvg2-bin \
  && rm -rf /var/lib/apt/lists/*

# Spritesmith をローカルインストール
RUN npm install spritesmith

# スプライト生成スクリプトをコピーして実行権限を付与
COPY ./generate-sprites.sh /app/generate-sprites.sh
RUN chmod +x /app/generate-sprites.sh

# 実行時に環境変数を上書きできるよう、デフォルト値を定義
ENV SVG_INPUT_DIR=/data/input/svg \
    PNG_INPUT_DIR=/data/input/png \
    PNG_TEMP_DIR=/tmp/png_icons \
    OUTPUT_DIR=/data/output \
    SPRITE_NAME=sprite

# コンテナ起動時にスクリプトを実行
CMD ["./generate-sprites.sh"]