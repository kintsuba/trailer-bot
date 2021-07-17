import times, json

type ReactionCount* = tuple
  reactionType: string
  count: int

type Note* = object
  id*: string
  text*: string
  userId*: string
  renoteCount*: int
  reactionCounts*: seq[ReactionCount]
  myRenoteId*: string
  createdAt*: DateTime
  localOnly*: bool
  copyOnce*: bool
  score*: int

type Settings* = object
  token*: string
  limitCounts*: int
  limitMinutes*: int

proc toNotes*(json: JsonNode): seq[Note] =
  var notes: seq[Note]
  for noteData in json:
    var note = Note(id: "", renoteCount: 0, reactionCounts: @[], myRenoteId: "",
        createdAt: now())
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
