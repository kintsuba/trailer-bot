import asyncdispatch, httpClient, json

let client = newAsyncHttpClient()
client.headers = newHttpHeaders({ "Content-Type": "application/json" })

const host = "misskey.m544.net/api/"

proc requestMisskey*(api: string, httpMethod: HttpMethod, body: string): Future[JsonNode] {.async.} =
  let response = await client.request("https://" & host & api, httpMethod = HttpPost, body = $body)
  let body = await response.body
  return body.parseJson()

proc getNotes*(token: string, userId: string, limit: int, sinceId: string, untilId: string): Future[JsonNode] {.async.} =
  let body = %*{
    "i": token,
    "userId": userId,
    "limit": limit,
    "sinceId": sinceId,
    "untilId": untilId
  }
  return await requestMisskey("users/notes", httpMethod = HttpPost, body = $body)

proc getGlobalTL*(token: string, limit: int): Future[JsonNode] {.async.} =
  let body = %*{
    "i": token,
    "limit": limit
  }
  return await requestMisskey("notes/global-timeline", httpMethod = HttpPost, body = $body)
proc getLocalTL*(token: string, limit: int): Future[JsonNode] {.async.} =
  let body = %*{
    "i": token,
    "limit": limit
  }
  return await requestMisskey("notes/local-timeline", httpMethod = HttpPost, body = $body)


proc renote*(token: string, renoteId: string, visibility: string): Future[JsonNode] {.async.} =
  let body = %*{
    "i": token,
    "renoteId": renoteId,
    "visibility": visibility
  }
  return await requestMisskey("notes/create", httpMethod = HttpPost, body = $body)