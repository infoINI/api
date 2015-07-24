elasticsearch = require 'elasticsearch'
url = require 'url'

config = require '../config'
logger = require '../logger'


LogToWinston = (config) ->
  @error = logger.error.bind(logger)
  @warning = logger.warn.bind(logger)
  @info = logger.info.bind(logger)
  @debug = logger.debug.bind(logger)
  @trace = (method, requestUrl, body, responseBody, responseStatus) ->
    logger.debug (
      """
      request: #{method + ' ' + url.format(requestUrl) + requestUrl.path}

      #{JSON.stringify(JSON.parse(body), null, 2)}

      response: #{responseStatus}
      #{JSON.stringify(JSON.parse(responseBody), null, 2)}

      """
    )
  @close = ->
  return @

class Search
  types: []
  registerType: (typeSpec) -> @types.push typeSpec


  constructor: ->
    @client = new elasticsearch.Client(
      host: 'localhost:9200'
      log: LogToWinston
    )
    @createUpdateMapping()

  createUpdateMapping: ->
    for type in @types
      name = type.name
      mapping.type.indexMapping
      @client.indices.putMapping(
        type: name
        body: mapping
      )

module.exports = new Search
