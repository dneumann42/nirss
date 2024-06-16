import std/[os, strutils, base64, htmlgen, sequtils, logging, xmlparser, xmltree]
import config
export config

type Post = object
  link, title: string
  description: string
  publishedDate: string

proc getFileName*(url: string): string =
  url.encode()

proc getFeedContent(url: string): Result[string, string] =
  let path = getCacheDir() / "nirss" / url.getFileName()
  if not fileExists(path):
    return err("No file exists")
  ok(readFile(path))

proc genFeed(feed: Feed): string =
  let feedContent = feed.url.getFeedContent()
  if feedContent.isErr:
    error(feedContent.errorOr(""))
    return htmlgen.p("Not found")
  let content = feedContent.get()
  let xml = parseXml(content)
  let child = xml.child("channel")
  if child.isNil:
    error("Failed to find channel element")
    return ""
  ""

proc buildDashboard*(cfg: var Config) =
  let posts = htmlgen.div(cfg.feeds.map(genFeed))
  let content = html(head(title("Dashboard")), body(posts)).join("")
  writeFile("dashboard.html", content)
  info("Built dashboard")
