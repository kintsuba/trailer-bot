import os, strutils, sequtils, asyncdispatch, json
import ../types, ../misskey

proc checkNote(note: Note, token: string): Future[JsonNode] {.async.} =
  if note.text.contains("トレーラーちゃん"):
    return await createReaction(token, note.id, "🚛")
    

proc reactNotes*(notes: seq[Note], token: string): Future[seq[JsonNode]] {.async.} =
  return notes.mapIt(await checkNote(it, token))
