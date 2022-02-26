import os, strutils, sequtils, asyncdispatch, json
import ../types, ../misskey

proc checkNote(note: Note, token: string): Future[bool] {.async.} =
  var bonus: int = 0

  # 独断と偏見によるボーナス
  if note.text.contains("俺タワー"): bonus += 1
  if note.text.contains("毎日こつこつ"): bonus += 1

  # note単体のチェック
  if not note.myRenoteId.isEmptyOrWhitespace or # 既にRenoteしていない
    note.localOnly or
    note.copyOnce or
    note.text.contains("#nobot") or
    note.text.contains("ログボ") or
    note.text.contains("ﾌｸﾞﾊﾟﾝﾁ") or
    note.score + bonus < 5: # ボーナス含めたスコアでチェック

    return false # 上記の条件を1つでも満たしていたら除外

  else:
    echo "Find a matched note!"
    echo "score: " & $note.score

    # ユーザー系をリクエストして使うやつだけJSONから変換して格納
    let user = await showUser(token, note.userId)
    let description = user["description"].getStr
    let isBot = user["isBot"].getBool

    # ユーザー系のチェック
    if
      description.contains("#nobot") or # bio に nobot が記入されている
      isBot: # そもそもBot

      return false # 以上のどれかなら除外
    else:
      echo "Find! Good luck!"
      sleep(5000) #ユーザーのリクエスト挟んでるので、負荷軽減のため一旦sleep
      return true # 全部くぐり抜けたやつだけtrue


proc filterPopularNotes*(notes: seq[Note], token: string): Future[seq[Note]] {.async.} =
  return notes.filterIt(await checkNote(it, token))
