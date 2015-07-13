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
  constructor: ->
    @client = new elasticsearch.Client(
      host: 'localhost:9200'
      log: LogToWinston
    )
    @createUpdateMapping()

  createUpdateMapping: ->
    mappings = {
      file:
        properties:
          availible:
            type: 'boolean'
          title:
            type: 'string'
          checksum:
            type: 'string'
          text:
            type: 'string'
          tags: # array of strings
            type: 'string'
          mime:
            type: 'string'
          size:
            type: 'long'
      dir:
        properties:
          availible:
            type: 'boolean'
          subdirs:
            type: 'string'
          files:
            type: 'string'
          tags: # array of strings
            type: 'string'
          description:
            type: 'string'
    }
    for name, mapping of mappings
      @client.indices.putMapping(
        type: name
        body: mapping
      )


module.exports = new Search
