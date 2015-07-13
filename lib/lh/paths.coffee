path = require 'path'

config = require '../config'
logger = require '../logger'

# static class for settings
class Paths
  @getFullPath: (_path) ->
    path.join(config.lhRoot, _path)

  @getFullUploadPath: (_path) ->
    path.join(config.lhUploads, _path)


module.exports = Paths
