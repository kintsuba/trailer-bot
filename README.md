# Trailer-chan Bot / トレーラーちゃんBot

## What's this?
It's a Misskey Bot, search popular note in GTL and LTL, and note it.

## How to use?
1. Compile source by nim, or download auto builded package (linux only).
2. make `settings.yaml` same as executable file directory.
3. edit settings file as below.
```yaml settings.yaml
%YAML 1.2
---
# Your Bot account's token
# あなたのアカウントの Misskey のトークン
token: "!*******************"

# Note interval(ms)
# 投稿間隔(ms)
interval: 900000

# Lower limit number of reaction + renote
# 投稿するリアクション数 + リノート数の下限
limitCounts: 5

# How many minutes before to get Notes
# 何分前までの投稿まで取得するか
limitMinutes: 180
```
4. run

## Who is Trailer-chan?
Trailer (トレーラー) is character of "俺タワー ～Over Legend Endless Tower～" based on the real world's "Trailer".
She is so clumsy girl and cute, motif of "Ant".