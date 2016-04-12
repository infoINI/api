walk = require 'walk'
yaml = require 'js-yaml'
path = require 'path'
fs = require 'fs'
Q = require 'q'

config = require '../config'
logger = require '../logger'
File   = require './file'
Paths  = require './paths'
Search = require './search'


class Dir
  @indexMapping:
    properties:
      available:
        type: 'boolean'
      subdirs:
        type: 'string'
      files:
        type: 'string'
      tags: # array of strings
        type: 'string'
      description:
        type: 'string'

  @readReadme: (_path) ->
    d = Q.defer()
    devider = '\n---\n'
    fullPath = Paths.getFullPath(path.join(_path, 'README.md'))

    fs.readFile fullPath, (err, data) ->
      if err
        d.reject err
        return
      text = data.toString()
      text = text.replace(/(\r\n|\n|\r)/gm,"\n")
      split = text.indexOf devider
      meta = yaml.safeLoad text.substring(0, split)
      body = text.substring split + devider.length
      d.resolve [meta, body]
    return d.promise

  @createContent: (_path, recursion) ->
    fullPath = Paths.getFullPath _path
    d = Q.defer()
    files = []
    dirs = []
    walker = walk.walk fullPath, { filters: [ '.' ], followLinks: true }
    walker.on 'file', (root, stat, next) ->
      return next() if stat.name == 'README.md'
      File.create(path.join(_path, stat.name)).then (file) ->
        files.push(file)
        next()
      , (e) ->
        logger.warn 'failed to create file', e.toString()
        next()
      .done()

    walker.on 'directory', (root, stat, next) ->
      Dir.create(path.join(_path, stat.name), recursion).then (dir) ->
        dirs.push(dir)
        next()
      , (e) ->
        logger.warn 'failed to create dir', e.toString()
        next()
      .done()

    walker.on 'end', ->
      d.resolve([dirs, files])

    return d.promise

  @create: (_path, recursion  = 0) ->
    logger.debug 'creating dir object', _path
    name = path.basename(_path)
    dirs = []
    files = []
    promise = null
    if recursion > 0
      promise = Q(_path).then =>
        @createContent(_path, recursion - 1).then ([d, f]) ->
          dirs = d
          files = f
    else
      promise = Q()

    promise.then ->
      Dir.readReadme(_path).then ([meta, body]) ->
        new Dir(_path, name, meta, body, files, dirs)
      , ->
        new Dir(_path, name, {}, '', files, dirs)
    .fail (e) ->
      logger.info 'failed to create dir', e.toString()
      return e



  constructor: (@path, @name, @meta, @text = '', @files = [], @dirs = []) ->
    @meta ?= {}
    @meta.tags ?= []

  toJSON: ->
    path: @path
    name: @name
    meta: @meta
    text: @text
    files: @files
    dirs: @dirs

  # add update dir in index
  index: (recurse = 0) ->



Search.registerType Dir


module.exports = Dir
