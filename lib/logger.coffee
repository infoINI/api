winston = require 'winston'

logger = new winston.Logger(
  transports: [
    new winston.transports.Console(colorize: true)
  ]
)

logger.setLevel = (options) ->
  if options.silent
    logger.level = 'error'
  if options.quiet
    logger.level = 'warn'
  if options.verbose
    logger.level = 'verbose'
  if options.debug
    logger.level = 'debug'

module.exports = logger
