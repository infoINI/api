Q = require 'q'
path = require 'path'
mmm = require 'mmmagic'
fs = require 'fs'

Paths  = require './paths'
config = require '../config'
logger = require '../logger'


magic = new mmm.Magic(mmm.MAGIC_MIME_TYPE)

class File
  @create: (_path) ->
    name = path.basename(_path)
    fullPath = Paths.getFullPath(_path)
    Q.ninvoke(magic, 'detectFile', fullPath).then (mime) ->
      Q.nfcall(fs.stat, fullPath).then (stat) ->
        new File(
          name,
          stat.size,
          mime,
          stat.mtime
        )

  constructor: (@name, @size, @mime, @lastChanged) ->

  # add /update file in index
  index: ->


module.exports = File
