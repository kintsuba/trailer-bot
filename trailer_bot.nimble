# Package

version       = "0.1.1"
author        = "kintsuba"
description   = "Trailer-chan bot for Misskey."
license       = "MIT"
srcDir        = "src"
bin           = @["trailer_bot"]



# Dependencies

requires "nim >= 0.10.2"
requires "yaml >= 0.13.0"
requires "redis >= 0.2.0"