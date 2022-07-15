import os, strutils, sequtils, asyncdispatch, json
import ../types, ../misskey

proc checkNote(note: Note, token: string): Future[bool] {.async.} =
  if note.text.contains("トレーラーちゃん"):
    discard= await createReaction(token, note.id, "🚛")
    sleep(5000)
    return true

  return false
    

proc reactNotes*(notes: seq[Note], token: string): Future[seq[Note]] {.async.} =
  return notes.filterIt(await checkNote(it, token))
