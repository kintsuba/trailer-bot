import asyncdispatch, json, redis, options


proc getRedisInfo*(): Future[(string, string)] {.async.} =
  let redisClient = await openAsync()

  let endNoteId = await redisClient.get("lastNoteId")
  let firstNoteId = await redisClient.get("firstNoteId")


  return (endNoteId, firstNoteId)
