require "./kemal_elm_chat/*"
require "kemal"

module KemalElmChat

  SOCKETS = [] of HTTP::WebSocket

  get "/" do |env|
    env.redirect "/index.html"
  end

  ws "/chat" do |socket|
    SOCKETS << socket

    socket.on_message do |message|
      SOCKETS.each { |socket| socket.send message }
    end

    socket.on_close do
      SOCKETS.delete socket
    end
  end

end

Kemal.run
