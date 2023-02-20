import strutils, sequtils, asyncdispatch, json
import ../types, ../misskey

proc checkNote(note: Note, token: string): Future[bool] {.async.} =
  var bonus: int = 0

  # 独断と偏見によるボーナス
  if note.text.contains("俺タワー"): bonus += 2
  if note.text.contains("毎日こつこつ"): bonus += 2

  # note単体のチェック
  if not note.myRenoteId.isEmptyOrWhitespace or # 既にRenoteしていない
    note.localOnly or
    note.copyOnce or
    note.text.contains("#nobot") or
    note.text.contains("ろぐぼ") or
    note.text.contains("ログボ") or
    note.text.contains("ﾌｸﾞﾊﾟﾝﾁ") or
    note.text.contains("おはよ") or
    note.text.contains("てすと") or
    note.text.contains("テスト") or
    note.score + bonus < 7: # ボーナス含めたスコアでチェック

    return false # 上記の条件を1つでも満たしていたら除外

  else:
    var adjustScore: int = 0

    echo "Find a matched note!"
    echo "score: " & $note.score

    # ユーザー系をリクエストして使うやつだけJSONから変換して格納
    let user = await showUser(token, note.userId)
    let description = user["description"].getStr
    let isBot = user["isBot"].getBool
    let host = user["host"].getStr
    let userId = user["id"].getStr

    # ユーザー系のチェック
    if
      description.contains("#nobot") or # bio に nobot が記入されている
      isBot: # そもそもBot

      echo "It's bot's Note."
      return false # 以上のどれかなら除外

    if host == "misskey.io":
      adjustScore -= 10
    if userId == "5cb377a8b622604a9118ae51":
      adjustScore -= 10

    await sleepAsync(5000) #ユーザーのリクエスト挟んでるので、負荷軽減のため一旦sleep

    if note.score + bonus + adjustScore >= 7:
      echo "Find! Good luck!"
      return true # 全部くぐり抜けたやつだけtrue
    else:
      echo "Not enough score."
      return false


proc filterPopularNotes*(notes: seq[Note], token: string):
  Future[seq[Note]] {.async.} =

  return notes.filterIt(await checkNote(it, token))
