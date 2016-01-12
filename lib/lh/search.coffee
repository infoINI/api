elasticsearch = require 'elasticsearch'
url = require 'url'

config = require '../config'
logger = require '../logger'


LogToWinston = (config) ->
  @error = logger.error.bind(logger)
  @warning = logger.warn.bind(logger)
  @info = logger.info.bind(logger)
  @debug = logger.debug.bind(logger)
  @trace = logger.debug.bind(logger)
  ###
  @trace = (method, requestUrl, body, responseBody, responseStatus) ->
    logger.debug (
      """
      request: #{method + ' ' + url.format(requestUrl) + requestUrl.path}

      #{JSON.stringify(JSON.parse(body), null, 2)}

      response: #{responseStatus}
      #{JSON.stringify(JSON.parse(responseBody), null, 2)}

      """
    )
  ###
  @close = ->
  return @

class Search
  types: []
  registerType: (typeSpec) -> @types.push typeSpec


  constructor: ->
    @client = new elasticsearch.Client(
      host: config.elasticHost
      log: LogToWinston
    )
    #@createUpdateMapping()

  index: (type, id, body) ->
    @client.create({
      index: 'lh'
      type: type
      id: id
      body: body
    })

  createUpdateMapping: ->
    logger.info 'search: creating index'
    @client.indices.create(
      index: 'lh'
    ).then(
      -> logger.info 'search: index created'
    , -> logger.info 'search: index already exists'
    ).then =>
      for type in @types
        name = type.name
        mapping = type.indexMapping
        logger.info 'search: [re]creating type: ' + name
        @client.indices.putMapping(
          index: 'lh'
          type: name
          body: mapping
        )

module.exports = new Search
