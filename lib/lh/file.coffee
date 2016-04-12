Q = require 'q'
path = require 'path'
mmm = require 'mmmagic'
fs = require 'fs'
textract = require 'textract'

Search = require './search'
Paths  = require './paths'
config = require '../config'
logger = require '../logger'


magic = new mmm.Magic(mmm.MAGIC_MIME_TYPE)

class File
  @indexMapping:
    properties:
      available:
        type: 'boolean'
      title:
        type: 'string'
      checksum:
        type: 'string'
      text:
        type: 'string'
      tags: # array of strings
        type: 'string'
      mime:
        type: 'string'
      size:
        type: 'long'
  @create: (_path) ->
    name = path.basename(_path)
    fullPath = Paths.getFullPath(_path)
    Q.ninvoke(magic, 'detectFile', fullPath).then (mime) ->
      Q.nfcall(fs.stat, fullPath).then (stat) ->
        f = new File(
          name,
          stat.size,
          mime,
          stat.mtime
        )
        f.id = _path
        Q.nfcall(textract, fullPath, {
          lang: 'deu'
        }).then (text) ->
          f.text = text
          f.index()
          return f
        , (err) ->
          logger.warn err
          f.index()
          return f

  constructor: (@name, @size, @mime, @lastChanged) ->

  # add /update file in index
  index: ->
    Search.index(@constructor.name, @id, {
      available: true # TODO
      title: @name
      checksum: '0' #TODO
      text: @text
      tags: [] # TODO
      mime: @mime
      size: @size
      # TODO lastChanged
    })

Search.registerType File
module.exports = File
