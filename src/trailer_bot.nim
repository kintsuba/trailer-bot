import ws, asyncdispatch
import json, strutils
import yaml/serialization, streams
import misskey

type Settings = object
  token: string

proc main() {.async.} =
  var settings: Settings;
  let s = newFileStream("settings.yaml")
  load(s, settings)

  let token = settings.token
  let ws = await newWebSocket("wss://misskey.m544.net/streaming?i=" & token)
  echo "Login Success !!"

  await ws.send(connectGlobalTLString);

  while true:
    let json = await ws.receiveStrPacket()
    var data : JsonNode
    try:
      data = parseJson(json)
    except JsonParsingError as e:
      if json != "":
        echo e.msg & "\n" & json;

    try:
      if $data["body"]["id"].getStr == "globaltl":
        let body = data["body"]["body"]
        let text = $body["text"].getStr
        echo text
        if text.contains("めいめい"):
          echo renote(token, $data{"body", "body", "id"}.getStr, "home")
    except AssertionError as e:
      if json != "":
        echo e.msg & "\n" & json;

asyncCheck main()
runForever()