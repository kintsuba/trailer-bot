import os, strutils, sequtils, asyncdispatch
import ../types, ../misskey

proc checkNote(note: Note, token: string): Future[bool] {.async.} =
  if note.text.contains("トレーラーちゃん"):
    let result = await createReaction(token, note.id, "🚛")
    sleep(5000)
    if result == true:
      echo "🚚 Zoom Zoom 🚚"
      return true
    else:
      return false
  else:
    return false

proc reactNotes*(notes: seq[Note], token: string): Future[seq[Note]] {.async.} =
  return notes.filterIt(await checkNote(it, token))
