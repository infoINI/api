markdown = require 'markdown'
Q = require 'q'
path = require 'path'
walk = require 'walk'

config = require '../config'
logger = require '../logger'

Dir = require './dir'
File = require './file'
Paths = require './paths'


class Page
  constructor: (@path, @dir, @files, @subdirs) ->

  toJSON: ->
    path     : @path
    markdown : @markdown
    html     : @html
    meta     : @meta
    files    : @files
    subdirs  : @subdirs

  @create: (_path = '/') ->
    logger.debug 'creating page', _path
    d = Q.defer()
    opts = {
      dir: null
      files: []
      subdirs: []
    }

    Dir.create(_path).then (dir) ->
      opts.dir = dir

    # walker: collect files, dirs
    fullPath = Paths.getFullPath(_path)
    walker = walk.walk fullPath, { filters: [ '.' ], followLinks: true }
    .on 'file', (root, stat, next) ->
      return next() if stat.name == 'README.md'
      File.create(path.join(_path, stat.name)).then (file) ->
        opts.files.push(file)
        next()
      , (e) ->
        logger.warn 'failed to create file', e.toString()
        next()

    .on 'directory', (root, stat, next) ->
      Dir.create(path.join(_path, stat.name)).then (dir) ->
        opts.subdirs.push(dir)
        next()
      , (e) ->
        logger.warn 'failed to create file', e.toString()
        next()

    .on 'end', ->
      d.resolve new Page(_path, opts.dir, opts.files, opts.subdirs)

    return d.promise

  # create/update page in index
  index: ->

module.exports = Page
