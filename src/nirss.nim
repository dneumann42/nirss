import std/[os, json, asyncdispatch, httpclient, strutils, options, sequtils, logging]
import dashboard
import results, cascade

proc getString(headers: HttpHeaders, key: string): Option[string] =
  if headers.hasKey(key):
    let header = headers[key]
    if header.len == 0:
      return none(string)
    some($header)
  else:
    none(string)

proc getLastModified(headers: HttpHeaders): Option[string] =
  headers.getString("last-modified")

proc getETag(headers: HttpHeaders): Option[string] =
  headers.getString("etag")

proc writeRssFeed(url, xml: string) =
  let basePath = getCacheDir() / "nirss"
  if existsOrCreateDir(basePath):
    let path = basePath / url.getFileName()
    writeFile(path, xml)
    info("Wrote feed: " & url)

proc updateFeed(feed: Feed): Future[Feed] {.async.} =
  var client = newAsyncHttpClient()
  if feed.lastModified != "":
    client.headers["If-Modified-Since"] = feed.lastModified
  if feed.etag != "":
    client.headers["If-None-Match"] = feed.etag

  let response = await client.request(feed.url, httpMethod = HttpGet, body = "")
  if response.status == $Http304:
    info("Skipped feed: " & feed.url)
    return feed

  let body = await response.body
  writeRssFeed(feed.url, body)
  cascade(feed):
    lastModified = response.headers.getLastModified().get(feed.lastModified)
    etag = response.headers.getETag().get(feed.etag)

proc updateFeeds(cfg: var Config) =
  cfg.feeds = waitFor cfg.feeds.map(updateFeed).all()

proc run(update = false, force = false, gen = false) =
  newConsoleLogger(lvlAll).addHandler()
  var cfg = Config.load().get()
  defer:
    cfg.save()
  if update:
    cfg.updateFeeds()
  if gen:
    cfg.buildDashboard()

when isMainModule:
  import cligen
  dispatch run
