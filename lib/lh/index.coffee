fs = require 'fs'
path = require 'path'
Q = require 'q'
express = require 'express'
multipart = require 'connect-multiparty'
markdown = require 'markdown'

config = require '../config'
logger = require '../logger'

Dir = require './dir'
Paths = require './paths'
File = require './file'


multipartMiddleware = multipart()

router = express.Router()


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
  Dir.create(pathParam, 1).then (dir) ->
    try
      res.json dir.toJSON()
    catch e
      res.status(500).end(e.toString())
  , (e) ->
    res.status(500).send(e.toString())
  .done()


router.get '/listhtml/*', (req, res) ->
  pathParam = req.params[0]
  Dir.create(pathParam, 2).then (dir) ->
    res.render('page', (
      title: 'LH: ' + dir.path
      path: dir.path
      files: dir.files
      dirs: dir.dirs
      description: markdown.markdown.toHTML(dir.text)
      meta: JSON.stringify(dir.meta, null, 2)
    ))
  , (e) ->
    res.status(500).end(e.toString())



module.exports = router
