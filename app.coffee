http = require('http')
express = require('express')
request = require('request')
net = require('net')

members = require('./members.js')
MensaFeed = require('./mensa')


app = express()



jRespond = (res,data) ->
  res.contentType('application/json')
  res.charset = 'utf-8'
  res.end(JSON.stringify(data))

cafeStatus = {}
tuerStatus = {}
mensaPlan = {}

refreshMensa = ->
  url = 'http://www.studentenwerk-berlin.de/speiseplan/rss/beuth/woche/kurz/0'
  request url, (err, res, body) ->
    m = new MensaFeed
    m.parseTable(body)
    mensaPlan = m.getPlan()


refreshCafe = ->
  req = http.request {
    host:'iniwlan.beuth-hochschule.de',
    port:4000,
    path:'/'
  }, (res) ->
    res.on 'data', (data) ->
      cafeStatus = JSON.parse(data)
      # value ignored
      cafeStatus.status = undefined
  .on 'error', ->
    console.error('request error')
  .end()



refreshTuer = ->
  client = new net.Socket

  client.on 'data', (data) ->
    pyStatus = JSON.parse(data)
    tuerStatus.status = pyStatus.tuer_offen?'OPEN':'CLOSED'
    client.destroy()

  client.on 'error', (e) ->
    console.error('error', e)

  client.on 'timeout', ->
    console.error('timeout')

  client.connect(51966, 'localhost')

setInterval refreshCafe, 1000
setInterval refreshTuer, 1000
setInterval refreshMensa, 30*60*1000

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
  res.contentType('text/xml')
  res.charset = 'utf-8'
  res.end(xml)

app.get '/api/combined.json', (req, res) ->
  console.log('get combined')
  combined = {}
  combined.pots = cafeStatus.pots
  combined.status = tuerStatus.status
  jRespond res, combined


app.get '/api/members.json', (req, res) ->
  members.getFSR().then (members) ->
    jRespond res,  members: members

app.get '/api/helpers.json', (req, res) ->
  members.getHelpers().then (members) ->
    jRespond res, members: members

app.get '/api/cafe.json', (req, res) ->
  console.log('get cafe')
  jRespond res, cafeStatus

app.get '/api/door.json', (req, res) ->
  console.log('get door')
  jRespond res, tuerStatus

app.get '/api/zuendstoff.pdf', (req, res) ->
  console.log('get zuendstoff')
  res.redirect(
    'http://infoini.de/redmine/attachments/download/422/zs-ss2015.pdf'
  )
  res.end()

app.get '/api/mensa.json', (req, res) ->
  console.log('get mensa')
  jRespond res, mensaPlan

app.use("/api", express.static(__dirname + '/static'))
app.listen(3000)

