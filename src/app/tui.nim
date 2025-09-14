# New version of the terminal UI for nirss

## Two views
## | FEEDS  | CONTENT |
## And for half screens
## Feed tabs, a, b, c
## | CONTENT    |

import std/[os, strutils]
import illwill

type
  NirssTUILayout = enum
    Horizontal
    Vertical

  NirssTUI = object
    feeds*: TerminalBuffer
    content*: TerminalBuffer
    displayBuffer*: TerminalBuffer

proc exitTUI() {.noconv.} =
  illwillDeinit()
  showCursor()
  quit(0)

proc renderFeeds(tui: var NirssTUI) =
  discard

proc render(tui: var NirssTUI) =
  tui.displayBuffer.copyFrom(tui.tabs, 0, 0, tui.tabs.width, tui.tabs.height, 0, 0)
  tui.displayBuffer.display()

proc startTUI*() =
  illwillInit(fullscreen = true)
  setControlCHook(exitTUI)
  hideCursor()

  var tui = NirssTUI(
    tabs: newTerminalBuffer(30, terminalHeight()),
    content: newTerminalBuffer(terminalWidth() - 30, terminalHeight()),
    displayBuffer: newTerminalBuffer(terminalWidth(), terminalHeight()),
  )

  while true:
    var key = getKey()

    case key
    of None:
      discard
    of Escape, Q:
      exitTUI()
    else:
      discard

    tui.render()
    sleep(20)

  exitTUI()

when isMainModule:
  startTUI()
