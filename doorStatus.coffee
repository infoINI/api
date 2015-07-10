Q = require 'q'
net = require 'net'
config = require './config'

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
      console.warn 'tuer: request failed', e.toString()
      d.reject(e)

    client.connect(config.tuerPort, config.tuerHost)
    return d.promise
}
