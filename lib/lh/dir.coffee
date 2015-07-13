walk = require 'walk'
yaml = require 'js-yaml'
path = require 'path'
fs = require 'fs'
Q = require 'q'

config = require '../config'
logger = require '../logger'
Paths  = require './paths'


class Dir
  @create: (_path) ->
    devider = '\n---\n'
    d = Q.defer()
    fullPath = Paths.getFullPath(path.join(_path, 'README.md'))
    name = path.basename(_path)
    text = ''
    meta = {}
    body = ''
    # todo sync
    fs.readFile fullPath, (err, data) ->
      return if err
      text = data.toString()
      text = text.replace(/(\r\n|\n|\r)/gm,"\n")
      split = text.indexOf devider
      meta = yaml.safeLoad text.substring(0, split)
      body = text.substring split + devider.length
    numFiles = 0
    numDirs = 0

    fullPath = Paths.getFullPath(_path)
    walk.walk fullPath, { filters: [ '.' ], followLinks: true }
    .on 'files', (root, fileStats, next) ->
      numFiles = fileStats.filter (stat) ->
        stat.name != 'README.md'
      .length
      next()

    .on 'directories', (root, dirStats, next) ->
      numDirs = dirStats.length
      next()

    .on 'end', ->
      d.resolve new Dir(name, meta, body, numFiles, numDirs)

    return d.promise


  constructor: (
    @name,
    @meta = {},
    @text = '',
    @files = 0,
    @dirs = 0
  ) ->
    @meta.tags ?= []

  # add update dir in index
  index: ->


module.exports = Dir
