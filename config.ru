require './lib/app_server'
require File.expand_path("#{File.dirname(__FILE__)}/../initializers/string", __FILE__)

$stdout.sync = true

$port     = ARGV[0]
$env      = ARGV[1]
$hostname = ARGV[2]

AppServer.instance.env = $env
AppServer.instance.hostname = $hostname

# Load environment setting.
require File.expand_path("../environments/#{$env}", __FILE__)

app_server = AppServer.instance
app_server.run(port: $port)
