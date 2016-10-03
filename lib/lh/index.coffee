fs = require 'fs'
path = require 'path'
Q = require 'q'
express = require 'express'
multipart = require 'connect-multiparty'
markdown = require 'markdown'
passport = require 'passport'
LdapStrategy = require('passport-ldapauth').Strategy

config = require '../config'
logger = require '../logger'


passport.serializeUser (user, done) ->
  done(null, JSON.stringify(user))

passport.deserializeUser (user, done) ->
  done(null, JSON.parse(user))

passport.use(
  new LdapStrategy(
    (
      server:
        url: config.ldapServerUrl
        bindDn: config.ldapBindDn
        bindCredentials: config.ldapBindCredentials
        searchAttributes: config.ldapSearchAttributes
        searchBase: config.ldapSearchBase
        searchFilter: config.ldapSearchFilter
    )
    ,
    (user, cb) ->
      if user?.department == 'Informatik und Medien' or user?.department == 'FB6'
        cb(null, user)
      else
        cb(new Error('user not part of FB6'))
  )
)

Dir = require './dir'
Paths = require './paths'
File = require './file'
Search = require './search'

Search.createUpdateMapping()

multipartMiddleware = multipart()

router = express.Router()

#router.use(express.cookieParser())
#router.use(express.bodyParser())
router.use(require('body-parser').urlencoded(extended: false))
router.use(require('cookie-parser')())
router.use(require('express-session')( secret: 'bla' ))
#router.use(express.session({ secret: 'keyboard cat' }))
router.use(passport.initialize())
router.use(passport.session())

#router.use(passport.initialize())
#router.use(passport.authenticate('ldapauth'))
ensureAuth = (req, res, next) ->
  if req.user || process.env.DISABLE_AUTH == 'true'
    next()
  else
    res.sendStatus(403)


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


router.post '/login', passport.authenticate('ldapauth'), (req, res) ->
  console.log 'login'
  if req.user
    res.sendStatus(200)
  else
    res.sendStatus(403)

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


router.get '/file/*', ensureAuth, (req, res) ->
  pathParam = req.params[0]
  fullPath = Paths.getFullPath(pathParam)
  res.sendFile fullPath


router.get '/list/*', ensureAuth, (req, res) ->
  pathParam = req.params[0]
  Dir.create(pathParam, 1).then (dir) ->
    try
      res.json dir.toJSON()
    catch e
      res.status(500).end(e.toString())
  , (e) ->
    res.status(500).send(e.toString())
  .done()


router.get '/listhtml/*', ensureAuth, (req, res) ->
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
