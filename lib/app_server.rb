require 'em-websocket'
require 'em-hiredis'
require 'dalli'
require 'rest_client'
require 'cassandra'

require 'singleton'
require 'logger'
require 'json'

require File.expand_path("#{File.dirname(__FILE__)}/../initializers/string", __FILE__)

class AppServer
  include Singleton

  attr_accessor :redis_host, :memcached_host, :proxy_host,
                :env, :hostname, :boot_at,
                :connections, :log, :emredis, :dalli

  def initialize
    @log = Logger.new(STDOUT)
    @connections = 0
    @boot_at = Time.now
  end

  def init_emredis
    @emredis = EM::Hiredis.connect(redis_host)
    @connections = 0
    log.info "Redis: #{@emredis}"
  end

  def init_dalli
    @dalli = Dalli::Client.new(memcached_host)
  end

  def add_connections
    @connections += 1
  end

  def delete_connections
    @connections -= 1
  end

  def system_info
    {
      hostname: hostname,
      boot_at: boot_at,
      connections: connections
    }
  end

  def update_system_info
    dalli.set("#{hostname}-info", system_info)
  end

  # Runner

  def run(config)
    EM.run do
      init_emredis
      init_dalli
      update_system_info

      EM::WebSocket.run(:host => "0.0.0.0", :port => config[:port]) do |ws|
        ws.onopen do |handshake|
          channel = handshake.path.gsub('/', '')

          case channel
          when 'system'
            ws.send system_info
          else
            add_connections

            pubsub = emredis.pubsub
            pubsub.subscribe(channel)
            pubsub.on(:message) do |m_channel, message|
              ws.send message if channel == m_channel
            end

            ws.onmessage do |message|
              if message.is_json?
                m = JSON.parse(message)

                case m['m_type']
                when 'ping'
                  #
                else
                  begin
                    emredis.publish channel, message
                    case m['m_type']
                    when 'active'
                      # RestClient.get "http://#{proxy_host}/active/#{channel}"
                    end
                  rescue => e
                    log.error e
                  end
                end
              end
            end

            ws.onclose do
              begin
                emredis.publish channel, "{\"m_type\":\"disconnect\"}"
                # RestClient.get "http://#{proxy_host}/disconnect/#{channel}"
              rescue => e
                log.error e
              end

              pubsub.unsubscribe(channel)
              delete_connections

              update_system_info
            end

            update_system_info
          end
        end
      end

      log.info "Init: em-websocket running."
    end
  end
end
