import os, asyncdispatch, streams, strutils, sequtils, json
import yaml/serialization
import misskey, types
import functions/redisutils, functions/filter

proc main() {.async.} =
  var settings: Settings
  let settingsFile = newFileStream("settings.yaml")
  load(settingsFile, settings)

  # Misskey にリクエスト → 人気の投稿だけをフィルター
  let gottenGtlJson = await getGlobalTL(settings.token, 100)
  sleep(5000)
  let gottenLtlJSON = await getLocalTL(settings.token, 100)
  sleep(5000)
  let gottenGtlNotes = gottenGtlJson.toNotes
  let gottenLtlNotes = gottenLtlJson.toNotes
  let gottenTotalNotes = concat(gottenGtlNotes, gottenLtlNotes)
  let filteredNotes = await gottenTotalNotes.filterPopularNotes(settings.token)

  # Redis に残っているものを取得
  let redisJson = await getRedisByJson("notes")
  let redisNotes = redisJson.toNotes

  # 上2つを合わせる
  var totalNotes = concat(redisNotes, filteredNotes)

  # 空じゃなければ一番上にあるやつをRenote → seqから削除
  if totalNotes.len != 0:
    discard await renote(settings.token, totalNotes[0].id, "home")
    totalNotes.delete(0, 0)

  # 残ったものは再度Redisに入れとく
  if totalNotes.len != 0:
    discard setRedis("notes", $(%*totalNotes))
  else:
  # 何も残ってなかったら空文字列を入れとく
    discard setRedis("notes", "{}")

waitFor main()
