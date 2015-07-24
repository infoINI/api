express = require 'express'
path = require 'path'

config = require './config'
logger = require './logger'

coffeeStatus = require './coffeeStatus'
doorStatus = require './doorStatus'

members = require './members.js'
MensaFeed = require './mensa'
mensaFeed = new MensaFeed

lh = require './lh'

members.setApiKey config.redmineAuthKey

app = express()
app.set 'view engine', 'jade'
app.set 'views', path.join(__dirname, 'views')



# logging
app.use (req, res, next) ->
  logger.verbose req.method, req.path
  next()

app.use '/api/lh', lh

# compatibility for infoini app
app.get '/api/status.xml', (req, res) ->
  coffeeStatus.get().then (cafeStatus) ->
    doorStatus.get().then (tuerStatus) ->
      xml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <infoini>
              <door isOpen="#{ tuerStatus.status }" />
              <cafe>
                <pot>
                  <status>#{ cafeStatus.pots[0].status }</status>
                  <level>#{ cafeStatus.pots[0].level }</level>
                </pot>
                <pot>
                  <status>#{ cafeStatus.pots[1].status }</status>
                  <level>#{ cafeStatus.pots[1].level }</level>
                </pot>
              </cafe>
            </infoini>
            """
      res.contentType 'text/xml'
      res.charset = 'utf-8'
      res.end xml
  , (e) -> res.status(500).send e

app.get '/api/combined.json', (req, res) ->
  coffeeStatus.get().then (cafeStatus) ->
    doorStatus.get().then (tuerStatus) ->
      combined = {}
      combined.pots = cafeStatus.pots
      combined.status = tuerStatus.status
      res.json combined
  , (e) -> res.status(500).send e


app.get '/api/members.json', (req, res) ->
  members.getFSR().then (members) ->
    res.json members: members
  , (e) -> res.status(500).send e

app.get '/api/helpers.json', (req, res) ->
  members.getHelpers().then (members) ->
    res.json members: members
  , (e) -> res.status(500).send e

app.get '/api/cafe.json', (req, res) ->
  coffeeStatus.get().then (data) ->
    res.json data
  , (e) -> res.status(500).send e

app.get '/api/door.json', (req, res) ->
  doorStatus.get().then (tuerStatus) ->
    res.json tuerStatus
  , (e) -> res.status(500).send e

app.get '/api/zuendstoff.pdf', (req, res) ->
  res.redirect(
    config.fileZuendstoff
  )
  res.end()

app.get '/api/mensa.json', (req, res) ->
  mensaFeed.get().then (mensaPlan) ->
    res.json mensaPlan
  , (e) -> res.status(500).send e



app.use('/api', express.static(__dirname + '/../static'))
app.listen(config.httpPort)

