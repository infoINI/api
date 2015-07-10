config = require './config'
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
    .on 'error', (e) ->
      console.warn 'cafe: request failed', e.toString()
      d.reject(e)
    .end()
    return d.promise
}
