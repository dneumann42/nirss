import std/[options, strformat]

type
  NirssCommandKind* = enum
    Argument
    Command

  NirssCommand* = object
    description*: string
    extendedHelp*: string
    case kind*: NirssCommandKind
    of Argument:
      ident*, value*: string
    of Command:
      short*, long*: string

proc defineCommand*(
    short: string, long: string, description = "", extendedHelp = ""
): NirssCommand =
  NirssCommand(
    kind: Command,
    short: short,
    long: long,
    description: description,
    extendedHelp: extendedHelp,
  )

proc defineArgument*(ident: string, description = "", extendedHelp = ""): NirssCommand =
  NirssCommand(
    kind: Argument, ident: ident, description: description, extendedHelp: extendedHelp
  )

proc getCommand*(commands: seq[NirssCommand], key: string): Option[NirssCommand] =
  for cmd in commands:
    case cmd.kind
    of Command:
      if cmd.short == key or cmd.long == key:
        return some(cmd)
    of Argument:
      if cmd.ident == key:
        return some(cmd)

proc assertKind*(cmd: NirssCommand, kind: NirssCommandKind) =
  assert(
    cmd.kind == kind, &"Unexpected argument kind, expected {kind} but got {cmd.kind} "
  )
