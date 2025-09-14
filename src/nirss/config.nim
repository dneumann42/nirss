import std/[os, json, logging, tables, macros, options]
import constants
export tables, json, options

type
  URL = string

  Feed* = object
    url*: URL

  FeedMeta* = object
    lastModified*: string
    etag*: string

  Config* = object
    feeds*: seq[Feed]
    appConfig*: AppConfig

  Meta* = object
    feeds*: Table[URL, FeedMeta]

  AppConfig* = object
    repo*: Option[string]
    bindings*: Table[string, string]

  MetaConfig* = object
    cfg*: Config
    meta*: Meta

  ConfigError = object of CatchableError

proc feeds*(cfg: MetaConfig): seq[Feed] =
  cfg.cfg.feeds

proc write*(cfg: Config) {.raises: [IOError, OSError].} =
  if not dirExists(ConfigDir):
    createDir(ConfigDir)
  writeFile(ConfigDir / "config.json", (%*cfg).pretty)
  try:
    info("Wrote config")
  except:
    raise newException(IOError, getCurrentExceptionMsg())

proc write*(meta: Meta) {.raises: [IOError, OSError].} =
  if not dirExists(CacheDir):
    createDir(CacheDir)
  writeFile(CacheDir / "meta.json", (%*meta).pretty)
  try:
    info("Wrote meta")
  except:
    raise newException(IOError, getCurrentExceptionMsg())

proc load*(
    T: type Config, create = true
): T {.raises: [OSError, IOError, KeyError, ValueError].} =
  if create and not fileExists(ConfigDir / "config.json"):
    createDir(ConfigDir)
    T().write()
    return T.load(false)
  let contents = readFile(ConfigDir / "config.json")
  contents.parseJson.to(T)

proc load*(
    T: type Meta, create = true
): T {.raises: [OSError, IOError, KeyError, ValueError].} =
  if create and not fileExists(CacheDir / "meta.json"):
    createDir(CacheDir)
    T().write()
    return T.load(false)
  let contents = readFile(CacheDir / "meta.json")
  contents.parseJson.to(T)

proc load*(
    T: type MetaConfig, create = true
): T {.raises: [IOError, OSError, KeyError, ValueError].} =
  T(cfg: Config.load(create), meta: Meta.load(create))

proc write*(cfg: MetaConfig) {.raises: [IOError, OSError].} =
  cfg.cfg.write()
  cfg.meta.write()

macro withConfig*(ident, blk) =
  quote:
    var `ident` = MetaConfig.load()
    `blk`
    `ident`.write()

when isMainModule:
  echo Config.load()
  echo Meta.load()
