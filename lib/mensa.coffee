Q = require 'q'
request = require 'request'
config = require './config'

xpath = require('xpath')
Dom = require('xmldom').DOMParser
Entities = require('html-entities').AllHtmlEntities

entities = new Entities



module.exports = class MensaFeed

  parseTable: (str) ->
    doc = new Dom().parseFromString(str)
    tableStr = xpath.select('//channel/item/description/text()', doc).toString()
    rootStr = '<root>' + entities.decode(tableStr) + '</root>'
    @table = new Dom().parseFromString(rootStr)
    
  query: (qStr) ->
    xpath.select(qStr, @table)

  getText: (nodes) ->
    for node in nodes
      xpath.select('text()', node).toString()

  queryStr: (qStr) ->
    @getText(@query(qStr))

  getDates: ->
    d = @queryStr('.//thead/tr/th')
    d.shift()
    d

  getRowsTitles: ->
    @queryStr('.//table/tr/th')

  getContents: (row, col) ->
    titles = @queryStr('.//table/tr[' + row + ']/td[' + col + ']/p/strong')
    #siegel: i.value for i in @query(
    #'.//table/tr[' + row + ']/td[' + col + ']/a/img[@class="siegel"]/@src')
    prices = @queryStr(\
    './/table/tr[' + row + ']/td[' + col + ']/p/span[@class="mensa_preise"]')
    for t, i in titles
      title: t
      price: prices[i]

  getPlan: ->
    plan = {}
    dates = @getDates()
    categories = @getRowsTitles()
    for d, di in dates
      plan[d] = {}
      for c, ci in categories
        plan[d][c] = @getContents(ci+1, di+1)
    return plan

  get: ->
    d = Q.defer()
    request config.mensaUrl, (err, res, body) ->
      m = new MensaFeed
      m.parseTable(body)
      mensaPlan = m.getPlan()
      d.resolve(mensaPlan)
    return d.promise
    

#m = new MensaPlan
#fs = require 'fs'
#fs.readFile __dirname + '/mensa.atom', (err, data) ->
#  return console.err err if err
#  m.parseTable(data.toString())
#  console.log(JSON.stringify(m.getPlan(), null, 2))
