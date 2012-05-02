#      Copyright (C) <2012> by <ladinu@gmail.com>
#
#		Permission is hereby granted, free of charge, to any person obtaining a copy
#		of this software and associated documentation files (the "Software"), to deal
#		in the Software without restriction, including without limitation the rights
#		to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#		copies of the Software, and to permit persons to whom the Software is
#		furnished to do so, subject to the following conditions:
#		
#		The above copyright notice and this permission notice shall be included in
# 	all copies or substantial portions of the Software.
#		
#		THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#		IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#		FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#		AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#		LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#		OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#		THE SOFTWARE.  

require 'xmlrpc'
require 'crypt'
require 'net/http'
require 'net/https'
require 'time'

class Request
  attr_accessor :use_ssl, :auth_token, :listener_id, :time_dif
  attr_reader   :auth_token, :xml_data, :response

  def initialize(host=nil, port=nil, path=nil, headers=nil, timeout=nil)

    @version = 34
    @host    = host || "www.pandora.com"
    @path    = path || "/radio/xmlrpc/v#{@version}?"
    @port    = port || 80
    @timeout = timeout || 15
    @use_ssl = true

    @headers = headers || {
                            'User-agent'     => 'Symphony/0.1',
                            'Content-type'   => 'text/xml',
                            'Acept-encodong' => 'identity'
                          }
    @http          = Net::HTTP.new(@host, @port)
    @https         = Net::HTTP.new(@host, 443)
    @https.use_ssl = true

    @rpc_parser    = XMLRPC::Parser.new
    @xml_data      = XMLRPC::Call.new
    @crypt         = Crypt.new

    @time_dif      = 0
    @listener_id   = nil
    @random_id     = "%07iP"% (Time.now.to_i % 10000000) # Random ID based on time
    @auth_token    = nil # Listiner id sent by pandora
    @special_calls = ['listener.authenticateListener', 'station.getStations']
  end

  def send(method_name, *params)
      # Make url using params
    @url_args = "rid=#{@random_id}"
    @url_args << "&lid=#{@listener_id}" if @listener_id
    @url_args << "&method=#{method_name.split('.')[1]}" # Method is everything after the . (dot)

    unless @special_calls.include? method_name
      params.each { |i| @url_args << "&arg=#{i}" }
    end

      # Insert time stamp and authtoken (if exist) to xml call
    params.unshift @auth_token if @auth_token
    params.unshift (Time.now.to_i + @time_dif) unless params.empty? and not @auth_token

      # Make xml call
    @xml_data.new_call (method_name, *params)
    @encrypted_call = @crypt.encrypt (@xml_data.xml)
    # Send the http
    self.send_http
  end

  def send_http
    if @use_ssl

      @rpc_parser.parse @https.request_post(@path+@url_args, @encrypted_call, @headers).read_body
      @response = @rpc_parser.response

    else

     @rpc_parser.parse @http.request_post(@path+@url_args, @encrypted_call, @headers).read_body
     @response = @rpc_parser.response

    end
  end

  def using_ssl?
    @use_ssl
  end

  def recevied_err?
    @response and @response.first == :fault
  end

end

