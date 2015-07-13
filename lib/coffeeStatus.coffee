config = require './config'
logger = require './logger'
http = require 'http'
Q = require 'q'

module.exports = {
  get: ->
    d = Q.defer()
    req = http.request {
      host: config.cafeHost
      port: config.cafePort
      path:'/'
    }, (res) ->
      res.on 'data', (data) ->
        cafeStatus = JSON.parse(data)
        # value ignored
        cafeStatus.status = undefined
        d.resolve(cafeStatus)
    # set connection timeout
    .on 'socket', (socket) ->
      socket.setTimeout 1000
      socket.on 'timeout', -> req.abort()
    .on 'error', (e) ->
      logger.info 'cafe: request failed', e.toString()
      d.reject(e)
    req.end()
    return d.promise
}
