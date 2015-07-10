program = require 'commander'
config = require '../config'

program
.option '-c, --config <path>', 'config path'
.parse process.argv

try
  config.load(program.config)
catch e
  console.error 'failed to load config:', e.message

require '../app'
