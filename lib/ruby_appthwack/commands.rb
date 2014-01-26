$:.push File.expand_path('../', __FILE__)

require 'commands/status'
require 'commands/report'
require 'commands/convert'
# must be last since it depends on others
require 'commands/run'