import std/[options, xmlparser, xmltree, xmltree, streams, strutils, macros, sets]
import config, print

type ParseFeedError* = object of CatchableError

## TODO: implementation of the duplin core metadata
## https://www.dublincore.org/specifications/dublin-core/dces/

## item or entry
type 
  Item* = object
    title*: string
    link*: string
    description*: string
    author*: string
    category*: string
    comments*: string
    enclosure*: string
    guid*: string
    pubDate*: string
    source*: string

  Channel* = object
    title*: string
    link*: string
    description*: string

    items*: seq[Item]

    # optional
    langauge*: string
    copywrite*: string
    managingEditor*: string
    webMaster*: string
    pubDate*: string
    lastBuildDate* : string
    category*: string
    generator*: string
    docs*: string
    cloud*: string
    ttl*: string
    image*: string
    ratings*: string
    skipHours*: string
    skipDays*: string
    ## textInput is not supported 

proc setField[T: string](val: var T, str: string) =
  val = str
proc setField[T](val: var seq[T], str: string) =
  discard

template implSetObjectField(obj: object, field, val): untyped =
  block fieldFound:
    for objField, objVal in fieldPairs(obj):
      if objField == field:
        setField(objVal, val)
        break fieldFound
    raise newException(ValueError, "unexpected field: " & field)

proc setObjectField[T: object](obj: var T, field, val: string) =
  implSetObjectField(obj, field, val)

proc parse*(source: string): Channel =
  result = Channel()
  var xml = parseXml(source)
  assert(xml.len == 1 and xml.tag() == "rss")
  let channel = xml[0]
  assert(channel.tag() == "channel")
  const ChannelElements = [
      "title", "link", "description", "generator", "langauge", "copywrite", "managingEditor", "webMaster", "pubDate", "lastBuildDate", "category", "docs", "cloud", "ttl", "image", "ratings", "skipHours", "skipDays"
  ].toHashSet()

  const ItemElements = [
      "title", "link", "description", "author", "category", "comments", "enclosure", "guid", "pubDate", "source"
  ].toHashSet()
  for elem in channel:
    if elem.tag in ChannelElements:
      result.setObjectField(elem.tag, elem.innerText())
    if elem.tag == "item":
      var item = Item()
      for itemElem in elem:
        if itemElem.tag in ItemElements:

          var content = itemElem.innerText()
          if itemElem.len > 0:
            var inner = itemElem[0]
            if inner.kind == xnCData:
              content = inner.text
          item.setObjectField(itemElem.tag, content)

        # https://www.dublincore.org/specifications/dublin-core/dcmi-terms/elements11/creator/
        elif itemElem.tag == "dc:creator":
          item.author = itemElem.innerText()
      result.items.add(item)
