import std/[os, json, logging]
import results; export results

type
  Feed* = object
    url*: string
    lastModified*: string
    etag*: string

  Config* = object
    feeds*: seq[Feed]

proc save*(cfg: Config) {.raises: [].} =
  try:
    writeFile(expandTilde("~/.nirss.json"), (%*cfg).pretty)
    info("Saved config")
  except:
    echo getCurrentExceptionMsg()

proc load*(T: type Config): Result[Config, string] {.raises: [].} =
  try:
    let contents = readFile(expandTilde("~/.nirss.json"))
    ok(contents.parseJson.to(Config))
  except:
    err("Failed to load config")
