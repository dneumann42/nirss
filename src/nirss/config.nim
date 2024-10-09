import std/[os, json, logging, tables]
import constants
export tables, json

type
  Feed* = object
    url*: string
  FeedMeta* = object
    lastModified*: string
    etag*: string
  Config* = object
    feeds*: seq[Feed]
  Meta* = object
    feeds*: Table[string, FeedMeta]

proc write*(cfg: Config) {.raises: [IOError, Exception].} =
  if not dirExists(ConfigDir):
    createDir(ConfigDir)
  writeFile(ConfigDir / "config.json", (%* cfg).pretty)
  info("Wrote config")

proc write*(meta: Meta) {.raises: [IOError, Exception].} =
  if not dirExists(CacheDir):
    createDir(CacheDir)
  writeFile(CacheDir / "meta.json", (%* meta).pretty)
  info("Wrote meta")

proc load*(T: type Config, create = true): T {.raises: [OSError, IOError, Exception].} =
  if create and not dirExists(ConfigDir):
    createDir(ConfigDir)
    T().write()
    return T.load(false)
  let contents = readFile(ConfigDir / "config.json")
  contents.parseJson.to(T)

proc load*(T: type Meta, create = true): T {.raises: [OSError, IOError, Exception].} =
  if create and not dirExists(CacheDir):
    createDir(CacheDir)
    T().write()
    return T.load(false)
  let contents = readFile(CacheDir / "meta.json")
  contents.parseJson.to(T)

when isMainModule:
  echo Config.load()
  echo Meta.load()
