import httpClient, json

const connectGlobalTLString* = """
{
  "type": "connect",
  "body": {
    "channel": "globalTimeline",
    "id": "globaltl"
  }
}
"""

let client = newHttpClient()
client.headers = newHttpHeaders({ "Content-Type": "application/json" })

const host = "misskey.m544.net/api/"

proc requestMisskey*(api: string, httpMethod: HttpMethod, body: string): JsonNode =
  let response = client.request("https://" & host & api, httpMethod = HttpPost, body = $body)
  return response.body.parseJson()

proc getNotes*(token: string, userId: string, limit: int, sinceId: string, untilId: string): JsonNode =
  let body = %*{
    "i": token,
    "userId": userId,
    "limit": limit,
    "sinceId": sinceId,
    "untilId": untilId
  }
  return requestMisskey("users/notes", httpMethod = HttpPost, body = $body)

proc renote*(token: string, renoteId: string, visibility: string): JsonNode =
  let body = %*{
    "i": token,
    "renoteId": renoteId,
    "visibility": visibility
  }
  return requestMisskey("notes/create", httpMethod = HttpPost, body = $body)