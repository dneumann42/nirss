import std/[os, json, logging, strformat]
import results; export results
{.push raises: [].}

type
  Feed* = object
    url*: string
    lastModified*: string
    etag*: string

  Config* = object
    feeds*: seq[Feed]

proc getNirssConfigDir(): string =
  let configDir = getConfigDir()
  &"{configDir}" / "nirss"

proc getConfigPath*(): string =
  getNirssConfigDir() / "nirss.json"

proc save*(cfg: Config) {.raises: [].} =
  try:
    writeFile(getConfigPath(), (%*cfg).pretty)
    info("Saved config")
  except:
    echo getCurrentExceptionMsg()

proc load*(T: type Config, create=true): Result[Config, string] {.raises: [].} =
  try:
    if create and not fileExists(getConfigPath()):
      createDir(getNirssConfigDir())
      Config().save()
      return Config.load(false)

    let contents = readFile(getConfigPath())
    ok(contents.parseJson.to(Config))
  except:
    err("Failed to load config")
