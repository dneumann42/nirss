import std/[os, json, asyncdispatch, httpclient, strutils, options, sequtils, logging, strformat, base64]
import constants, config

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

proc updateFeed*(feed: Feed, meta: FeedMeta): Future[(Feed, FeedMeta)] {.async.} =
  var client = newAsyncHttpClient()
  if meta.lastModified != "":
    client.headers["If-Modified-Since"] = meta.lastModified
  if meta.etag != "":
    client.headers["If-None-Match"] = meta.etag

  let response = await client.request(feed.url, httpMethod = HttpGet, body = "")
  if response.status == $Http304:
    info("Skipped feed: " & feed.url)
    return (feed, meta)
  let body = await response.body
  writeRssFeed(feed.url, body)

  let newMeta = FeedMeta(
    lastModified: response.headers.getLastModified().get(meta.lastModified),
    etag: response.headers.getETag().get(meta.etag)
  )
  (feed, newMeta)

proc updateFeeds*(cfg: var Config, meta: var Meta) =
  let pairs = waitFor cfg.feeds.mapIt(updateFeed(it, meta.feeds[it.url])).all()
  meta.feeds = pairs.mapIt((it[0].url, it[1])).toTable()
  cfg.feeds = pairs.mapIt(it[0])
