import json, os, sequtils, asyncdispatch
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
    note.myRenoteId = noteData["myRenoteId"].getStr

    notes.add(note);
  
  return notes

proc renoteTarget() {.async.} =
  let globalNotesData = await getGlobalTL(token, 100)
  let localNotesData = await getLocalTL(token, 50)
  let notes = globalNotesData.jsonToNotes.concat(localNotesData.jsonToNotes)

  var targetNote = Note(id: "", renoteCount: 0, reactionCounts: @[])
  for note in notes:
    if note.myRenoteId == "" and targetNote.allCount < note.allCount:
      targetNote = note
  
  if targetNote.id != "":
    echo await renote(token, targetNote.id, "home")

proc action() {.async.} =
  try:
    await renoteTarget()
  except KeyError as e:
    echo e.msg
  except:
    echo "HTTP Error. Auto Retry...."
    await action()
    

proc main() {.async.} =
  load(s, settings)
  token = settings.token
  while true:
    await action()
    sleep(600000) # 多分10分

waitFor main()
runForever()