import std/[os, json, asyncdispatch, httpclient, strutils, options, sequtils, logging, strformat, base64, uri, algorithm, sugar]
import constants, config, print
export config

type
  InvalidURL = object of Exception

proc getString(headers: HttpHeaders, key: string): Option[string] =
  if not headers.hasKey(key):
    return none(string)
  let header = headers[key]
  if header.len == 0:
    return none(string)
  some($header)

proc getLastModified(headers: HttpHeaders): Option[string] =
  headers.getString("last-modified")

proc getETag(headers: HttpHeaders): Option[string] =
  headers.getString("etag")

proc getFileName*(url: string): string =
  url.encode()

proc writeRssFeed(url, xml: string) =
  if existsOrCreateDir(CacheDir):
    let path = CacheDir / url.getFileName()
    writeFile(path, xml)
    info("Wrote feed: " & url)

proc updateFeed*(feed: Feed, meta: Meta): Future[(Feed, FeedMeta)] {.async.} =
  let feedMeta = meta.feeds[feed.url]
  var client = newAsyncHttpClient()
  if feedMeta.lastModified != "":
    client.headers["If-Modified-Since"] = feedMeta.lastModified
  if feedMeta.etag != "":
    client.headers["If-None-Match"] = feedMeta.etag

  let response = await client.request(feed.url, httpMethod = HttpGet, body = "")
  if response.status == $Http304:
    echo("Skipped feed: " & feed.url)
    return (feed, feedMeta)
  let body = await response.body
  writeRssFeed(feed.url, body)

  let newMeta = FeedMeta(
    lastModified: response.headers.getLastModified().get(feedMeta.lastModified),
    etag: response.headers.getETag().get(feedMeta.etag)
  )
  (feed, newMeta)

proc updateMetas(cfg: var Config, meta: var Meta) =
  for feed in cfg.feeds:
    if not meta.feeds.hasKey(feed.url):
      meta.feeds[feed.url] = FeedMeta()

proc updateFeeds*(cfg: var Config, meta: var Meta) =
  updateMetas(cfg, meta)
  let pairs = waitFor cfg.feeds.mapIt(updateFeed(it, meta)).all()
  meta.feeds = pairs.mapIt((it[0].url, it[1])).toTable()
  cfg.feeds = pairs.mapIt(it[0])

proc addFeed*(cfg: var Config, meta: var Meta, url: string, update = true) {.raises: [ValueError, Exception].} =
  if cfg.feeds.any((it) => it.url == url):
    return
  let feed = Feed(url: url)
  cfg.feeds.add(feed)
  if not meta.feeds.hasKey(url):
    meta.feeds[url] = FeedMeta()
  if update:
    updateFeeds(cfg, meta)

proc getFeedContent*(cfg: Config, meta: Meta, url: string): string =
  if not meta.feeds.hasKey(url):
    return "<p>Not found.</p>"
  let path = CacheDir / url.getFileName()
  echo("READING")
  readFile(path)

when isMainModule:
  var cfg = Config.load()
  var meta = Meta.load()
  cfg.addFeed(meta, "https://lukesmith.xyz/index.xml")
  cfg.write()
  meta.write()
