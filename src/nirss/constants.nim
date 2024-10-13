import std/[os, json, logging, tables]

const ConfigDir* = static:
  getConfigDir() / "nirss"

const CacheDir* = static:
  getCacheDir() / "nirss"

