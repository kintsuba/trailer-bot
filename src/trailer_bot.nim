import json, os, sequtils, asyncdispatch, httpclient
import yaml/serialization, streams
import misskey

type ReactionCount = tuple
  reactionType: string
  count:int

type Note = object
  id: string
  renoteCount: int
  reactionCounts: seq[ReactionCount]
  myRenoteId: string;

type Settings = object
  token: string
  interval: int
  limit: int

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
    var note: Note
    note.id = noteData["id"].getStr
    note.renoteCount = noteData["renoteCount"].getInt
    var rcSeq: seq[ReactionCount]
    for rc in noteData["reactionCounts"].pairs:
      rcSeq.add((reactionType: rc.key, count: rc.val.getInt))
    note.reactionCounts = rcSeq;
    note.myRenoteId = noteData["myRenoteId"].getStr

    notes.add(note);
  
  return notes

proc renoteTarget(untilId: string) {.async.} =
  let globalNotesData: JsonNode =
    if untilId == "":
      await getGlobalTL(token, 100)
    else:
      await getGlobalTL(token, 100, untilId)
  let localNotesData = await getLocalTL(token, 50)

  let globalNotes = globalNotesData.jsonToNotes
  let localNotes = localNotesData.jsonToNotes
  let notes = globalNotes.concat(localNotes)

  var targetNote = Note(id: "", renoteCount: 0, reactionCounts: @[])
  for note in notes:
    if note.myRenoteId == "" and targetNote.allCount < note.allCount:
      targetNote = note
  
  if targetNote.id == "": return
  
  if targetNote.allCount >= settings.limit:
    # カウントの下限条件を満たしていたらリノートする
    echo await renote(token, targetNote.id, "home")
  else:
    # ダメだったらちょっと待ってからもう1回リクエスト
    sleep(1000)
    await renoteTarget(globalNotes[99].id)


proc action() {.async.} =
  try:
    await renoteTarget("")
  except KeyError as e:
    echo e.msg
  except ProtocolError as e:
    echo e.msg
    await action()

proc main() {.async.} =
  load(s, settings)
  token = settings.token
  while true:
    await action()
    sleep(settings.interval)

waitFor main()
runForever()