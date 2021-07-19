import asyncdispatch, redis, json, strutils

proc getRedisByString*(key: string): Future[string] {.async.} =
  let redisClient = await openAsync()

  let response = await redisClient.get(key)

  let result =
    if response != redisNil:
      response
    else:
      ""
  return result

proc getRedisByJson*(key: string): Future[JsonNode] {.async.} =
  let value = await getRedisByString(key)
  let result =
    if value.isEmptyOrWhitespace:
      "{}".parseJson
    else:
      value.parseJson

  return result

proc setRedis*(key: string, value: string): Future[void] {.async.} =
  let redisClient = await openAsync()
  await redisClient.setk(key, value)
