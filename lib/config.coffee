yaml = require 'js-yaml'
fs = require 'fs'

defaults = require './config.defaults'


config = {
  # function to load other configs
  load: (path = '/etc/inid.yaml') ->
    text = fs.readFileSync(path)
    userConfig = yaml.safeLoad text
    for k, v of userConfig
      if k == 'load'
        console.warn '"load" not allowed as config key'
      else
        config[k] = v
}

for k,v of defaults
  config[k] = v

module.exports = config
