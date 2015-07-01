http = require 'http'
express = require 'express'
request = require 'request'
net = require 'net'


config = require './config.defaults'
try
  config[k] = v for k,v of require './config'
catch e
  console.warn 'can not load config, using defaults', e.toString()

members = require './members.js'
MensaFeed = require './mensa'
lh = require './lh'

members.setApiKey config.redmineAuthKey

app = express()
app.set 'view engine', 'jade'


app.use '/api/lh', lh.router

lh.Paths.setArchiveRoot config.lhRoot
lh.Paths.setUploadRoot config.lhUploads



cafeStatus = {}
tuerStatus = {}
mensaPlan = {}

refreshMensa = ->
  request config.mensaUrl, (err, res, body) ->
    m = new MensaFeed
    m.parseTable(body)
    mensaPlan = m.getPlan()


refreshCafe = ->
  req = http.request {
    host: config.cafeHost
    port: config.cafePort
    path:'/'
  }, (res) ->
    res.on 'data', (data) ->
      cafeStatus = JSON.parse(data)
      # value ignored
      cafeStatus.status = undefined
  .on 'error', (e) ->
    console.warn 'cafe: request failed', e.toString()
  .end()



refreshTuer = ->
  client = new net.Socket

  client.on 'data', (data) ->
    pyStatus = JSON.parse(data)
    tuerStatus.status = if pyStatus.tuer_offen then 'OPEN' else 'CLOSED'
    client.destroy()

  client.on 'error', (e) ->
    console.warn 'tuer: request failed', e.toString()


  client.connect(config.tuerPort, config.tuerHost)

# TODO use events instead of polling where possible
# TODO add evented longpolling/socket.io API
setInterval refreshCafe, config.refreshIntervalCafe
setInterval refreshTuer, config.refreshIntervalTuer
setInterval refreshMensa, config.refreshIntervalMensa

refreshCafe()
refreshTuer()
refreshMensa()


# compatibility for infoini app
app.get '/api/status.xml', (req, res) ->
  console.log('get status.xml')
  console.log(cafeStatus)

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

app.get '/api/combined.json', (req, res) ->
  console.log('get combined')
  combined = {}
  combined.pots = cafeStatus.pots
  combined.status = tuerStatus.status
  res.json combined


app.get '/api/members.json', (req, res) ->
  members.getFSR().then (members) ->
    res.json members: members

app.get '/api/helpers.json', (req, res) ->
  members.getHelpers().then (members) ->
    res.json members: members

app.get '/api/cafe.json', (req, res) ->
  console.log('get cafe')
  res.json cafeStatus

app.get '/api/door.json', (req, res) ->
  console.log('get door')
  res.json tuerStatus

app.get '/api/zuendstoff.pdf', (req, res) ->
  console.log('get zuendstoff')
  res.redirect(
    config.fileZuendstoff
  )
  res.end()

app.get '/api/mensa.json', (req, res) ->
  console.log('get mensa')
  res.json mensaPlan


app.get '/api/mensa.json', (req, res) ->
  console.log('get mensa')
  res.json mensaPlan


app.use("/api", express.static(__dirname + '/static'))
app.listen(config.httpPort)

