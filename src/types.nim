import json

type ReactionCount* = tuple
  reactionType: string
  count: int

type Note* = object
  id*: string
  text*: string
  userId*: string
  myRenoteId*: string
  localOnly*: bool
  copyOnce*: bool
  score*: int

type Settings* = object
  token*: string
  limitCounts*: int
  limitMinutes*: int

proc toNotes*(json: JsonNode): seq[Note] =
  if json == "{}".parseJson:
    return @[]

  var notes: seq[Note]
  for noteData in json:
    var note = Note(id: "", score: 0, myRenoteId: "")
    note.id = noteData["id"].getStr
    note.text = noteData["text"].getStr
    note.userId = noteData["userId"].getStr
    note.myRenoteId = noteData["myRenoteId"].getStr
    note.localOnly = noteData["localOnly"].getBool
    note.copyOnce = noteData["copyOnce"].getBool
    note.score = noteData["score"].getInt

    notes.add(note);

  return notes
