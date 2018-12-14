require 'socket'
require 'base64'
require 'json'

module HS1xx
  class Plug

    def initialize(ip_address)
      @ip_address = ip_address
    end

    def on
      send_to_plug('{"system": {"set_relay_state": {"state": 1}}}')
    end

    def off
      send_to_plug('{"system": {"set_relay_state": {"state": 0}}}')
    end

    def on?
      send_to_plug('{"system": {"get_sysinfo": {}}}')['system']['get_sysinfo']['relay_state'] == 1
    end

    def off?
      !on?
    end

    private

    def send_to_plug(payload)
      socket = Socket.tcp(@ip_address, 9999)
      socket.write(encrypt(payload))
      string = ''
      while (string << socket.getc) do
        begin
          if string.length > 5
            output = JSON.parse(decrypt(string))
            break
          end
        rescue JSON::ParserError => e
          # not real JSON - fetch more data
        end
      end
      socket.close
      return output
    ensure
      socket.close rescue nil
    end

    def encrypt(payload)
      output = []
      key = 0xAB
      payload.bytes do |b|
        output << (b ^ key)
        key = (b ^ key)
      end
      a = [output.size, *output]
      a.pack('NC*')
    end

    def decrypt(payload)
      key = 0xAB
      array = []
      payload.bytes[4..-1].each do |b, i|
        array << (b ^ key)
        key = b
      end
      array.pack('C*')
    end
  end
end
