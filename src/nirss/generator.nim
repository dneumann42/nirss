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
    var hidden: seq[string] = @[]
    for (index, item) in enumerate(channel.items):
      let pubDate = item.pubDate
      let formatted = pubDate.substr(0, pubDate.len() - 16)
      if index < 3:
        items.add htmlgen.div(
          htmlgen.div(
            class="row-2 space pubdate",
            h3(a(href=item.link, item.title)),
            time(formatted)
          ),
          p(item.description.descriptionPreview()),
        )
      else:
        hidden.add htmlgen.div(
          h3(a(href=item.link, item.title)),
          p(item.description.descriptionPreview()),
          time(formatted)
        )

    htmlgen.div(
      class="feed-card-container",
      htmlgen.div(
        class="col-2",
        h2(class="underline", a(href=channel.link, channel.title)),
        items.join(""),
      ),
      button("More", onclick="morePosts(event)"),
      htmlgen.div(
        class="hidden",
        htmlgen.div(
          class="feed-card-container",
          hidden.join("")
        )
      )
    ) 
  except:
    "<p>404</p>"

proc generate*() =
  withConfig(cfg):
    let htm = "<!DOCTYPE html>\n" & htmlgen.html(
      head(
        title("Dashboard"),
        style(
        """
        * { font-family: sans-serif; }
        body { 
          margin: 2em; 
          background-color: black; 
          color: white; 
          flex: 0; 
        }
        a { text-decoration: none; color: white; }
        button { 
          color: white;
          border: none;
          cursor: pointer;
          align-self: flex-start; 
          background-color: rgba(0, 0, 0, 0); 
          text-decoration: underline;
          display: inline-block;
          font-size: 1.5em;
        }
        .col { display: flex; flex-direction: column; row-gap: 8px; }
        .col-2 { display: flex; flex-direction: column; row-gap: 16px; }
        .row { display: flex; flex-direction: row; col-gap: 8px; }
        .row-2 { display: flex; flex-direction: row; col-gap: 16px; }
        .space { justify-content: space-between; }
        .center { align-items: center; }
        .underline { text-decoration: underline; }
        p { margin: 0; padding: 0; }
        h1 { margin: 0; padding: 0; }
        h2 { margin: 0; padding: 0; }
        h3 { margin: 0; padding: 0; }
        .hidden { display: none; }
        .shown { display: block; }
        .pubdate { color: gray; }
        .header { font-size: 3em; }
        .header-container { 
          display: flex; 
          flex-direction: row; 
          align-items: center; 
          justify-content: center; 
          margin-bottom: 2em;
        }
        .feed-card-container {
          align-self: flex-start;
          display: flex;
          flex-direction: column;
          row-gap: 1em;
          padding: 1em;
          background-color: #222;
          justify-content: space-between;
          box-shadow: 10px 10px 0px #444;
          border: 1px solid #666;
        }
        .feeds-container {
          display: grid;
          align-items: start;
          grid-template-columns: 1fr 1fr;
          gap: 2em;
        }
        @media (max-width: 800px) {
          .feeds-container {
            display: grid;
            align-items: start;
            grid-template-columns: 1fr;
            gap: 2em;
          }
        }
        """
        ),
        script("""
        function morePosts(event) {
          const hiddenDiv = event.target.nextSibling;
          console.log(event)
          if (hiddenDiv.className == "hidden") {
            hiddenDiv.className = "shown";
            event.target.innerText = "Less";
          } else {
            hiddenDiv.className = "hidden";
            event.target.innerText = "More";
          }
        }
        """)
      ),
      body(
        htmlgen.div(
          class="header-container",
          h1("RSS Feeds", class="header") 
        ),
        htmlgen.div(
          class="feeds-container",
          cfg.feeds.mapIt(generateFeed(it)).join("")
        )
      )
    )
    writeFile("dashboard.html", htm)
