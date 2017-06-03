Q = require 'q'
net = require 'net'
config = require './config'
logger = require './logger'

module.exports = {
  get: ->
    d = Q.defer()
    tuerStatus = {}
    client = new net.Socket

    client.on 'data', (data) ->
      pyStatus = JSON.parse(data)
      tuerStatus.status = if pyStatus.tuer_offen then 'OPEN' else 'CLOSED'
      client.destroy()
      d.resolve(tuerStatus)

    client.on 'error', (e) ->
      logger.info 'tuer: request failed', e.toString()
      d.resolve({})

    client.connect(config.tuerPort, config.tuerHost)
    return d.promise
}

