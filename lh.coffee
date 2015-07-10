fs = require 'fs'
path = require 'path'
Q = require 'q'
walk = require 'walk'
markdown = require 'markdown'
yaml = require 'js-yaml'
mmm = require 'mmmagic'
express = require 'express'
multipart = require 'connect-multiparty'
elasticsearch = require 'elasticsearch'
config = require './config'



multipartMiddleware = multipart()

router = express.Router()
magic = new mmm.Magic(mmm.MAGIC_MIME_TYPE)


# static class for settings
class Paths
  @getFullPath: (_path) ->
    path.join(config.archiveRoot, _path)

  @getFullUploadPath: (_path) ->
    path.join(config.uploadRoot, _path)


class Index
  constructor: ->
    @client = new elasticsearch.Client(
      host: 'localhost:9200'
      log: 'trace'
    )
    @createUpdateMapping()

  createUpdateMapping: ->
    mappings = {
      file:
        properties:
          availible:
            type: 'bool'
          title:
            type: 'string'
          checksum:
            type: 'string'
          text:
            type: 'string'
          tags: # TODO
            type: 'string'
          mime:
            type: 'string'
          size:
            type: 'long'
      dir:
        properties:
          availible:
            type: 'bool'
          subdirs:
            type: 'string'
          files:
            type: 'string'
          description:
            type: 'string'
    }
    for name, mapping of mappings
      @client.indices.putMapping(
        type: name
        body: mapping
      )


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


class Dir

  @create: (_path) ->
    devider = '\n---\n'
    d = Q.defer()
    fullPath = Paths.getFullPath(path.join(_path, 'README.md'))
    name = path.basename(_path)
    text = ''
    meta = {}
    body = ''
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

    .on 'directory', (root, stat, next) ->
      Dir.create(path.join(_path, stat.name)).then (dir) ->
        opts.subdirs.push(dir)
        next()

    .on 'end', ->
      d.resolve new Page(_path, opts.dir, opts.files, opts.subdirs)

    return d.promise

  # create/update page in index
  index: ->

handleFileUpload = (file, dest) ->
  d = Q.defer()
  targetPath = path.join(dest, file.originalFilename)
  fs.createReadStream(file.path)
  .pipe(fs.createWriteStream(targetPath))
  .on 'err', d.reject
  .on 'close', ->
    # Remove old file and unlink it
    fs.unlink file.path, (err) ->
      if err
        return d.reject(err)

      file.path = targetPath
      file.name = file.originalFilename

      d.resolve(file)
  d.promise


router.post '/file/', multipartMiddleware, (req, res) ->
  files = req.files.files
  note = req.body.note
  # if only one file submited, make an array anyway
  unless files.length
    files = [ files ]

  # destination directory
  dirname = Paths.getFullUploadPath (new Date).toISOString()
  noteFile = path.join dirname, 'note.txt'
  # response status
  status = []

  # create folder and writeout note.txt
  promise = Q.nfcall(fs.mkdir, dirname)
  .then Q.nfcall(fs.writeFile, noteFile, note)

  # write out files
  for file in files
    promise = promise.then Q.fcall(handleFileUpload, file, dirname)
    .then (f) ->
      status.push(file.originalFilename + ' OK')
    , (err) ->
      status.push(err.toString())

  # respond
  promise.then ->
    res.json status
  promise.fail (e) ->
    status.push(e.toString())
    res.json status, 500


router.get '/file/*', (req, res) ->
  pathParam = req.params[0]
  fullPath = Paths.getFullPath(pathParam)
  res.sendFile fullPath


router.get '/list/*', (req, res) ->
  pathParam = req.params[0]
  Page.create(pathParam).then (page) ->
    res.json page.toJSON()


router.get '/listhtml/*', (req, res) ->
  pathParam = req.params[0]
  Page.create(pathParam).then (page) ->
    res.render 'page',
      title: 'LH: ' + page.path
      path: page.path
      files: page.files
      dirs: page.subdirs
      description: markdown.markdown.toHTML(page.dir.text)
      meta: JSON.stringify(page.meta, null, 2)



module.exports = {
  Page: Page
  Paths: Paths
  router: router
  index: new Index
}

