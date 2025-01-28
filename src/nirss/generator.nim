# Generates a webpage for rss

import std / [htmlgen, sequtils, strutils, os, base64, strformat, enumerate, re]

import ../nirss/[config, parser, constants]

proc getFileName*(url: string): string =
  url.encode()

proc getFeedContent*(url: string): string =
  let path = CacheDir / url.getFileName()
  readFile(path)

proc getChannel(feed: Feed): parser.Channel =
  var channels {.global.} = initTable[string, parser.Channel]()
  if channels.hasKey(feed.url):
    return channels[feed.url]
  let content = getFeedContent(feed.url)
  channels[feed.url] = content.parse()
  return channels[feed.url]

proc descriptionPreview(description: string): string =
  result = description.replace(re"<[^>]*>", "").substr(0, 120) & "..."

proc generateFeed*(feed: Feed): string =
  try:
    let channel = feed.getChannel()

    var items: seq[string] = @[]
    for (index, item) in enumerate(channel.items):
      if index >= 3:
        break
      items.add htmlgen.div(
        h3(item.title),
        p(item.description.descriptionPreview()),
        a(href=item.link, "open")
      )

    htmlgen.div(
      class="feed-card-container",
      h2(channel.title),
      items.join("")
    ) 
  except:
    "<p>404</p>"

proc generate*() =
  withConfig(cfg):
    let htm = htmlgen.html(
      head(
        title("Dashboard"),
        style(
        """
        body { margin: 0; }
        p { margin: 0; padding: 0; }
        h1 { margin: 0; padding: 0; }
        h2 { margin: 0; padding: 0; }
        h3 { margin: 0; padding: 0; }
        .header-container { display: flex; flex-direction: row; align-items: center; justify-content: center; }
        .feed-card-container {
          display: flex;
          flex-direction: column;
          row-gap: 1em;
        }
        .feeds-container {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 2em;
        }
        """
        )
      ),
      body(
        htmlgen.div(
          class="header-container",
          h1("Feeds") 
        ),
        htmlgen.div(
          class="feeds-container",
          cfg.feeds.mapIt(generateFeed(it)).join("")
        )
      )
    )
    writeFile("dashboard.html", htm)
