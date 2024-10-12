import std/[terminal, enumerate, math, options, tables]
import print

import ../nirss/config
import ../nirss/api

type AppStateKind = enum
  feeds
  reader
  settings

type AppState = object
  case kind: AppStateKind
    of feeds: discard
    of reader: 
      feed: Option[Feed]
    of settings: discard

type App = object
  state: AppState
  meta: Meta
  config: Config
  running: bool

  stateChanged = false
  feedCursor = 0

proc changeState(app: var App, newState: AppState) =
  app.state = newState
  app.stateChanged = true

proc getFeedContent(app: App, feed: Feed): string =
  var cache {.global.} = initTable[string, string]()
  if cache.hasKey(feed.url):
    return cache[feed.url]
  cache[feed.url] = getFeedContent(app.config, app.meta, feed.url)
  return cache[feed.url]

proc update*(app: var App) =
  let ch = getch()

  if ch == 'q':
    app.running = false
  if ch == 'k':
    app.feedCursor = euclMod((app.feedCursor - 1), app.config.feeds.len())
  if ch == 'j':
    app.feedCursor = euclMod((app.feedCursor + 1), app.config.feeds.len())
  if ch == 'l':
    let feed = app.config.feeds[app.feedCursor]
    app.changeState(AppState(kind: reader, feed: feed.some()))
  if ch == 'h' and app.state.kind == reader:
    app.changeState(AppState(kind: feeds))

proc renderFeedsState*(app: App) =
  for idx, feed in enumerate(app.config.feeds):
    if idx == app.feedCursor:
      stdout.styledWriteLine(fgBlack, bgWhite, feed.url)
    else:
      stdout.writeLine(feed.url)

proc renderFeed*(app: App) =
  assert(app.state.kind == reader)
  assert(app.state.feed.isSome())
  echo(app.getFeedContent(app.state.feed.get()))

const RenderStates = [
  feeds: renderFeedsState,
  reader: renderFeed,
  settings: renderFeedsState,
]

proc render*(app: App) =
  setCursorPos(0, 0)
  if app.stateChanged:
    eraseScreen()
  RenderStates[app.state.kind](app)

proc run*() =
  proc onExit() =
    resetAttributes()
  defer: onExit()
  eraseScreen()

  var app = App(
    state: AppState(kind: feeds),
    meta: Meta.load(),
    config: Config.load(),
    running: true
  )
  app.render()

  while app.running:
    app.update()
    app.render()

when isMainModule:
  run()
