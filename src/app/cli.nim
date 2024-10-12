import std/parseopt
import ../nirss/api
import print

proc run() =
  var cfg = Config.load()
  var meta = Meta.load()

  var help = true
  
  for kind, key, val in getopt():
    help = false
    if kind == cmdArgument:
      if key == "update" or key == "u":
        updateFeeds(cfg, meta)
      if key == "list" or key == "l":
        for f in cfg.feeds:
          print(f)
    if kind == cmdLongOption or kind == cmdShortOption:
      if key == "add" or key == "a":
        cfg.addFeed(meta, val)
        echo("Added feed.")

  if help:
    echo("add update list")

  cfg.write()
  meta.write()

when isMainModule:
  run()
