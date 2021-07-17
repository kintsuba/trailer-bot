import asyncdispatch, streams, strutils
import yaml/serialization
import misskey, types
import functions/get

proc main() {.async.} =
  var settings: Settings
  let settingsFile = newFileStream("settings.yaml")
  load(settingsFile, settings)

  let (endNoteId, firstNoteId) = await getRedisInfo()

  let json =
    if endNoteId.isEmptyOrWhitespace:
      echo "こっち:"
      await getGlobalTL(settings.token, 100)
    else:
      echo "そっち:"
      await getGlobalTL(settings.token, 100)

  let notes: seq[Note] = json.toNotes

  for note in notes:
    echo note.text

waitFor main()
