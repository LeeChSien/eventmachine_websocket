require './lib/app_server'
require File.expand_path("#{File.dirname(__FILE__)}/../initializers/string", __FILE__)

$stdout.sync = true

$port      = ARGV[0]
$env       = ARGV[1]
$hostname  = ARGV[2]
$redis     = ARGV[3] ||= 'redis://0.0.0.0:6379'
$memcached = ARGV[4] ||= 'localhost:11211'
$proxy     = ARGV[5] ||= 'localhost:3000'

app_server = AppServer.instance

app_server.env = $env
app_server.hostname = $hostname
app_server.redis_host = $redis
app_server.memcached_host = $memcached
app_server.proxy_host = $proxy

app_server.run(port: $port)
