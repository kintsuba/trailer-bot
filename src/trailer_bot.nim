import json, os, times, asyncdispatch, httpclient, random, strutils, net, math
import yaml/serialization, streams
import misskey

type ReactionCount = tuple
  reactionType: string
  count: int

type Note = object
  id: string
  text : string
  userId: string
  renoteCount: int
  reactionCounts: seq[ReactionCount]
  myRenoteId: string
  createdAt: DateTime
  localOnly: bool
  copyOnce: bool
  score: int

type Settings = object
  token: string
  limitCounts: int
  limitMinutes: int

var settings: Settings;
let s = newFileStream("settings.yaml")

var token: string

proc countToInt(rcs: seq[ReactionCount]): int =
  var count = 0
  for rc in rcs:
    count += rc.count

  return count

proc allCount(note: Note): int =
  return note.renoteCount + note.reactionCounts.countToInt

proc jsonToNotes(json: JsonNode): seq[Note] =
  var notes: seq[Note]
  for noteData in json:
    var note = Note(id: "", renoteCount: 0, reactionCounts: @[], myRenoteId: "", createdAt: now())
    note.id = noteData["id"].getStr
    note.text = noteData["text"].getStr
    note.userId = noteData["userId"].getStr
    note.renoteCount = noteData["renoteCount"].getInt
    var rcSeq: seq[ReactionCount]
    for rc in noteData["reactionCounts"].pairs:
      rcSeq.add((reactionType: rc.key, count: rc.val.getInt))
    note.reactionCounts = rcSeq;
    note.myRenoteId = noteData["myRenoteId"].getStr
    note.createdAt = noteData["createdAt"].getStr.parse("yyyy-MM-dd'T'hh:mm:ss'.'fff'Z'")
    note.localOnly = noteData["localOnly"].getBool
    note.copyOnce = noteData["copyOnce"].getBool
    note.score = noteData["score"].getInt

    notes.add(note);
  
  return notes

proc renoteTarget(untilId: string = "", lastNote: Note = Note(id: "", renoteCount: 0, reactionCounts: @[], myRenoteId: "", createdAt: now())) {.async.} =
  let notesData: JsonNode =
    if untilId == "":
      await getGlobalTL(token, 100)
    else:
      await getGlobalTL(token, 100, untilId)
  
  if $notesData == "":
    return

  let notes = notesData.jsonToNotes

  var targetNote = lastNote
  for note in notes:
    if note.myRenoteId == "" and not note.localOnly and not note.copyOnce and targetNote.score < note.score:
      if not note.text.contains("#nobot") and not note.text.contains("ログボ") and not note.text.contains("ﾌｸﾞﾊﾟﾝﾁ"):
        let user = await showUser(token, note.userId)
        let description = user["description"].getStr
        let isBot = user["isBot"].getBool
        # bio に #nobot があるかBotなら除外
        if not description.contains("#nobot") and not isBot:
          let followingCount = user["followingCount"].getInt
          let followersCount = user["followersCount"].getInt
          if followingCount != 0 and followersCount != 0:
            var bonus = 0
            if note.text.contains("俺タワー"): bonus += 1
            if note.text.contains("毎日こつこつ"): bonus += 1
            if targetNote.score < note.score - ( 0.95 * (log(followersCount.toFloat, 3.2) - 1.15)).toInt + bonus:
              targetNote = note
              echo "[" & $targetNote.score & "]" & " " & targetNote.text
              echo notes[99].id
        sleep(500)

  if targetNote.id != "" and targetNote.score >= settings.limitCounts:
    # 該当する投稿があって、カウントの下限条件を満たしていたらリノートする
    discard await renote(token, targetNote.id, "home")
  elif targetNote.id != "" and targetNote.createdAt.toTime < (getTime() - settings.limitMinutes.minutes - 9.hours):
    # 指定時間以上前のやつだったら諦めてそれをリノートする
    discard await renote(token, targetNote.id, "home")
  else:
    # ダメだったらちょっと待ってから、それより前をもう1回リクエスト
    sleep(500)
    await renoteTarget(notes[99].id, targetNote)

proc fall() {.async.} =
  let text: string = 
    case rand(5)
    of 0:
      "いったたたぁ……。今日も転んじゃいましたぁ……"
    of 1:
      "あわわわわ……いたっ。転んじゃいましたぁ"
    of 2:
      "うぇ！？……はわわ、いたいですぅ"
    of 3:
      "ぐへっ"
    of 4:
      "これで配達完了っと……あれ、もしかして私、荷物積み忘れました……！？"
    of 5:
      "私が活躍する毎日こつこつ俺タワーもぜひプレイしてくださいね！え、私の活躍ですか？えーと……"
    else:
      "はわわわわ……"
  
  echo await note(token, text, "public")

proc action() {.async.} =
  randomize()
  if 0 == rand(499): # 1/500 で転ぶ
    try:
      await fall()
    except ProtocolError as e:
      echo e.msg
      await action()
    except SslError as e:
      echo e.msg
      await action()

  else:  
    try:
      await renoteTarget()
    except KeyError as e:
      echo e.msg
    except ProtocolError as e:
      echo e.msg
      await action()
    except SslError as e:
      echo e.msg
      await action()

proc main() {.async.} =
  load(s, settings)
  token = settings.token
  
  await action()

waitFor main()