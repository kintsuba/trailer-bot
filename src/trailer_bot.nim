import os, asyncdispatch, streams, strutils, sequtils, json, random
import yaml/serialization
import misskey, types
import functions/redisutils, functions/filter, functions/react

proc main() {.async.} =
  var settings: Settings
  let settingsFile = newFileStream("config/settings.yaml")
  load(settingsFile, settings)

  var advertisements: seq[Advertisement]
  let advertisementsFile = newFileStream("config/advertisements.yaml")
  load(advertisementsFile, advertisements)

  randomize()

  # Misskey にリクエスト → 人気の投稿だけをフィルター
  let gottenGtlJson = await getGlobalTL(settings.token, 100)
  sleep(5000)
  let gottenLtlJSON = await getLocalTL(settings.token, 100)
  sleep(5000)
  let gottenGtlNotes = gottenGtlJson.toNotes
  let gottenLtlNotes = gottenLtlJson.toNotes
  let gottenTotalNotes = concat(gottenGtlNotes, gottenLtlNotes)
  let reactedNotes = await gottenTotalNotes.reactNotes(settings.token)
  let filteredNotes = await gottenTotalNotes.filterPopularNotes(settings.token)

  # Redis に残っているものを取得
  let redisJson = await getRedisByJson("notes")
  let redisNotes = redisJson.toNotes

  # 上2つを合わせる
  var totalNotes = concat(redisNotes, filteredNotes)

  # 空じゃなければ一番上にあるやつをRenote → seqから削除
  if totalNotes.len != 0:
    discard await renote(settings.token, totalNotes[0].id, "home")
    totalNotes.delete(0..0)

  # 空だったときはランダムで広告を投稿する
  else:
    if rand(3000) == 0:
      let pick = rand(0..advertisements.len-1)
      discard await note(settings.token, advertisements[pick].text, "home",
          advertisements[pick].fileIds)

  # 残ったものは再度Redisに入れとく
  if totalNotes.len != 0:
    discard setRedis("notes", $(%*totalNotes))
  else:
  # 何も残ってなかったら空文字列を入れとく
    discard setRedis("notes", "{}")

waitFor main()
