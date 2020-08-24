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
    if note.myRenoteId == "" and not note.localOnly and not note.copyOnce and not note.text.contains("#nobot") and targetNote.allCount < note.allCount:
      let user = await showUser(token, note.userId)
      let description = user["description"].getStr
      # bio に #nobot があったら除外
      if not description.contains("#nobot"):
        let followersCount = user["followersCount"].getInt
        if followersCount != 0:
          if targetNote.allCount < note.allCount - (followersCount.toFloat.log10.toInt - 1):
            targetNote = note
        else:
          if targetNote.allCount < note.allCount:
            targetNote = note
          
      sleep(1000)
  
  if targetNote.id != "" and targetNote.allCount >= settings.limitCounts:
    # 該当する投稿があって、カウントの下限条件を満たしていたらリノートする
    echo await renote(token, targetNote.id, "home")
  elif targetNote.id != "" and targetNote.createdAt.toTime < (getTime() - settings.limitMinutes.minutes - 9.hours):
    # 指定時間以上前のやつだったら諦めてそれをリノートする
    echo await renote(token, targetNote.id, "home")
  else:
    # ダメだったらちょっと待ってから、それより前をもう1回リクエスト
    sleep(1000)
    await renoteTarget(notes[99].id, targetNote)

proc fall() {.async.} =
  let text: string = 
    case rand(3)
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
    else:
      "はわわわわ……"
  
  echo await note(token, text, "home")

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