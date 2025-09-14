import std/[parseopt, sets, options, strformat, sugar, os, terminal]

import ../nirss/api
import ../nirss/generator

import commands

let nirssCommands =
  @[
    defineCommand("u", "update", description = "Update configured RSS feeds"),
    defineCommand("l", "list", description = "  List the configured RSS feeds"),
    defineCommand("g", "generate", description = "Generates a html file of the feeds"),
    defineArgument("add", description = "      Add a new feed to the config"),
    defineCommand("h", "help", description = "  Shows this help screen"),
  ]

proc printHelp(commands: seq[NirssCommand]) =
  stdout.styledWriteLine(fgWhite, "Usage: nirss <command>? [--<option>:<value>]")
  stdout.styledWriteLine(fgWhite, "Commands:")
  for cmd in commands:
    if cmd.kind != Command:
      continue
    stdout.styledWriteLine(
      fgWhite, "  ", cmd.short, ", ", cmd.long, "    ", fgCyan, cmd.description
    )
  stdout.styledWriteLine(fgWhite, "Arguments:")
  for cmd in commands:
    if cmd.kind != Argument:
      continue
    stdout.styledWriteLine(fgWhite, "  ", cmd.ident, "    ", fgCyan, cmd.description)

proc handleCommand(command: NirssCommand, arguments: seq[NirssCommand]) =
  withConfig(cfg):
    case command.long
    of "update":
      cfg.updateFeeds()
    of "list":
      for feed in cfg.cfg.feeds:
        echo feed
    of "generate":
      generate()
    of "help":
      printHelp(nirssCommands)
    else:
      echo("Unknown command '" & command.long & "'")

proc handleArgument(argument: NirssCommand, arguments: seq[NirssCommand]) =
  withConfig(cfg):
    case argument.ident
    of "add":
      cfg.addFeed(argument.value)
    else:
      echo("Unknown argument '" & argument.ident & "'")

proc handleCommands(commands: seq[NirssCommand]) =
  assert(commands.len() > 0, "No commands")
  let command = commands[0]
  var
    arguments = newSeq[NirssCommand]()
    rest = newSeq[NirssCommand]()
  for i in 1 ..< commands.len:
    if commands[i].kind != Argument:
      for j in i ..< commands.len:
        rest.add(commands[j])
      break
    arguments.add(commands[i])
  if command.kind == Argument:
    handleArgument(command, arguments)
  else:
    handleCommand(command, arguments)
  if rest.len > 0:
    handleCommands(rest)

proc run() =
  proc collectCommand(key, value: string): NirssCommand =
    let cmd = nirssCommands.getCommand(key)
    if cmd.isNone:
      echo("Unknown argument '" & key & "'")
      quit(1)
    result = cmd.get()
    if result.kind == Argument:
      result.value = value

  let commands: seq[NirssCommand] = collect:
    for kind, key, val in getopt():
      collectCommand(key, val)

  if commands.len() == 0:
    printHelp(nirssCommands)
  else:
    handleCommands(commands)

when isMainModule:
  run()
