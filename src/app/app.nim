import std / [ terminal, enumerate, math, options, tables, strutils, htmlparser, xmltree ]
import print

import ../nirss/config
import ../nirss/api
import ../nirss/parser

type AppStateKind = enum
  feeds
  item
  channel
  settings

type AppState = object
  case kind: AppStateKind
    of feeds: discard
    of channel: 
      feed: Option[Feed]
      itemCursor: int
    of item:
      item: Option[Item]
      scroll: int
    of settings: discard

type App = object
  state: AppState
  config: MetaConfig
  running: bool
  redraw = true

  stateChanged = false
  itemCount = 0
  feedCursor = 0
  padding = 8

var states: seq[AppState] = @[]

proc changeState(app: var App, newState: AppState) =
  states.add(app.state)
  app.state = newState
  app.stateChanged = true
  app.redraw = true

proc popState(app: var App) {.raises: [].} =
  try:
    let state = states.pop()
    app.state = state
    app.stateChanged = true
    app.redraw = true
  except:
    echo getCurrentExceptionMsg()

proc getFeedContent(app: App, feed: Feed): string =
  var cache {.global.} = initTable[string, string]()
  if cache.hasKey(feed.url):
    return cache[feed.url]
  cache[feed.url] = getFeedContent(app.config.cfg, app.config.meta, feed.url)
  return cache[feed.url]

proc getChannel(app: App, feed: Feed): parser.Channel =
  var channels {.global.} = initTable[string, parser.Channel]()
  if channels.hasKey(feed.url):
    return channels[feed.url]
  let content = app.getFeedContent(feed)
  channels[feed.url] = content.parse()
  return channels[feed.url]

proc update*(app: var App) =
  let ch = getch()

  app.stateChanged = false
  app.redraw = false

  if app.state.kind == channel:
    let state = app.state
    let channel = app.getChannel(state.feed.get())
    app.itemCount = channel.items.len()

  proc tryMoveCursor(app: var App, d: int) =
    case app.state.kind:
      of channel: 
        app.state.itemCursor = euclMod((app.state.itemCursor + d), app.itemCount)
      of item:
        app.state.scroll += d
        if app.state.scroll < 0:
          app.state.scroll = 0
      else:
        app.feedCursor = euclMod((app.feedCursor + d), app.config.feeds.len())
    app.redraw = true

  if ch == 'q':
    app.running = false
  if ch == 'k':
    app.tryMoveCursor(-1)
  if ch == 'j':
    app.tryMoveCursor(1)
  if ch == 'K':
    app.tryMoveCursor(-5)
  if ch == 'J':
    app.tryMoveCursor(5)
  if ch == 'l':
    case app.state.kind:
      of feeds:
        let feed = app.config.feeds[app.feedCursor]
        app.changeState(AppState(kind: channel, feed: feed.some()))
      of channel:
        let feed = app.config.feeds[app.feedCursor]
        let channel = app.getChannel(feed)
        app.changeState(AppState(kind: item, item: channel.items[app.state.itemCursor].some()))
      else:
        discard
  if ch == 'h':
    app.popState()

proc renderFeedsState*(app: App) =
  setCursorPos(0, 0)
  stdout.styledWriteLine(styleBright, styleUnderscore, "RSS Feeds")
  setCursorPos(0, 1)

  let height = terminalHeight() - 3
  let rangeMin = if app.feedCursor > height - 4: app.feedCursor - (height - 4) else: 0

  for idx, feed in enumerate(app.config.feeds[rangeMin..<app.config.feeds.len()]):
    if idx > height:
      break
    if idx == app.feedCursor:
      stdout.eraseLine()
      stdout.styledWriteLine(fgBlack, bgWhite, feed.url)
    else:
      stdout.writeLine(feed.url)
  setCursorPos(0, app.feedCursor)

proc renderChannel*(app: App) =
  assert(app.state.kind == channel)
  assert(app.state.feed.isSome())

  let state = app.state
  let channel = app.getChannel(state.feed.get())
  stdout.styledWriteLine(styleBright, styleUnderscore, channel.title)

  let height = terminalHeight() - 2
  let rangeMin = if state.itemCursor > height - 3: state.itemCursor - (height - 3) else: 0
  for idx, item in enumerate(channel.items[rangeMin..<channel.items.len()]):
    if idx > height:
      break
    if idx == state.itemCursor - rangeMin:
      stdout.styledWrite(fgBlack, bgWhite, item.title)
    else:
      let w = min(terminalWidth() - 2, item.title.len)
      stdout.write(item.title.substr(0, w))
    if idx < height:
      stdout.write("\n")
      stdout.eraseLine()

proc renderNode*(node: XmlNode, content: var string) =
  case node.kind:
    of xnElement:
      for sub in node:
        renderNode(sub, content)
        if sub.kind == xnText:
          continue
        if sub.kind == xnElement:
          if sub.tag in ["em", "span"]:
            continue
        content &= "\n"
    of xnText:
      content &= node.innerText
    else:
      echo("unexpected kind: " & $node.kind)

proc renderItem*(app: App) =
  assert(app.state.kind == item)
  assert(app.state.item.isSome())
  let item = app.state.item.get()

  var xml = parseHtml(item.description)
  if xml.kind == xnCData:
    xml = parseHtml(xml.text)

  var content = ""
  renderNode(xml, content)
  let lines = content.splitLines() 

  var idx = 0 
  for line in lines[max(0, min(app.state.scroll, lines.len))..<lines.len]:
    idx += 1
    if idx > terminalHeight() - 2:
      continue
    # truncate, scroll when cursor is hovering
    let w = min(terminalWidth() - 1, line.len())
    stdout.eraseLine()
    stdout.writeLine(line.substr(0, w))
  
const RenderStates = [
  feeds: renderFeedsState,
  item: renderItem,
  channel: renderChannel,
  settings: renderFeedsState,
]

proc render*(app: App) =
  setCursorPos(0, 0)
  if app.stateChanged:
    eraseScreen()
  if app.redraw:
    RenderStates[app.state.kind](app)

proc run*() =
  proc onExit() =
    resetAttributes()
  defer: onExit()
  eraseScreen()
  hideCursor()

  withConfig(config):
    var app = App(
      state: AppState(kind: feeds),
      config: config,
      running: true
    )

    app.render()

    while app.running:
      app.update()
      app.render()

when isMainModule:
  run()
