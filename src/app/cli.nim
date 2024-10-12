import std/parseopt
import ../nirss/api
import print

proc run() =
  withConfig(cfg):
    var help = true
    for kind, key, val in getopt():
      help = false
      if kind == cmdArgument:
        if key == "update" or key == "u":
          cfg.updateFeeds()
        if key == "list" or key == "l":
          for f in cfg.feeds:
            print(f)
      if kind == cmdLongOption or kind == cmdShortOption:
        if key == "add" or key == "a":
          cfg.addFeed(val)
          echo("Added feed.")

    if help:
      echo("add update list")

when isMainModule:
  run()
