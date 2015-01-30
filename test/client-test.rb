require 'em-websocket-client'

EM.run do
  conn = EventMachine::WebSocketClient.connect("ws://svr-websocket1.herokuapp.com/49e17af311dd2c18e63a9c52a89c13ca")

  conn.callback do
    conn.send_msg "\{\"m_type\":\"message\"\}"
  end

  conn.errback do |e|
    puts "Got error: #{e}"
  end

  conn.stream do |msg|
    puts "<#{msg}>"
    if msg.data == "\{\"m_type\":\"message\"\}"
      conn.close_connection
    end
  end

  conn.disconnect do
    puts "gone"
    EM::stop_event_loop
  end
end
