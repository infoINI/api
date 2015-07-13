program = require 'commander'

config = require '../lib/config'
logger = require '../lib/logger'


program
  .option '-c, --config <path>', 'config path'
  .option '-v, --verbose'
  .option '-d, --debug'
  .option '-q, --quiet'
  .option '-s, --silent'
.parse process.argv
logger.setLevel program

try
  config.load program.config
catch e
  logger.error 'failed to load config:', e.message

logger.info 'starting', (new Date).toISOString()

require '../lib/app'
