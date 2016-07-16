require "./kemal_elm_chat/*"
require "kemal"

module KemalElmChat

  sockets = [] of HTTP::WebSocket
  messages = [] of String

  get "/" do |env|
    env.redirect "/index.html"
  end

  ws "/chat" do |socket|
    sockets << socket
    socket.send messages.to_json

    socket.on_message do |message|
      messages = (messages + [message]).last(50)
      sockets.each { |socket|
        socket.send [ message ].to_json
      }
    end

    socket.on_close do
      sockets.delete socket
    end
  end

end

Kemal.run
