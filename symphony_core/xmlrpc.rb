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


module XMLRPC

  class Call
    attr_reader :xml

    def new_call(method, *params)

      if valid_method_name? method
        @method = method
        self.make_xml params
      else
        raise  "[!] Method name '#{method}' is an invalid XMLRPX method name"
      end
    end

    def valid_method_name?(methodName)
      # Check if methodName conforms with XMLRPC specs
      if methodName.class == String
        # XMLRPC method name specs
        valid_method_name = /^[[:alpha:][:digit:]\.:_\/]+$/
       
       if methodName.match valid_method_name
         true
       else
         false
       end

      else
        raise "Method '#{methodName}' must be a string"
      end
    end

    def make_xml(params)

      @xml = "<?xml version=\"1.0\" ?><methodCall><methodName>#{@method}</methodName><params>"

      unless params.empty?
        params.each do |i|
          @xml << "<param><value>"
          @xml << make_xml_value(i)
          @xml << "</value></param>"
        end
      end
      @xml << "</params></methodCall>"
    end
                      
    def make_xml_value(i)
      case i
      when String
        "<string>#{i}</string>"
      when Fixnum
        "<int>#{i}</int>"
      when TrueClass
        "<boolean>1</boolean>"
      when FalseClass
        "<boolean>0</boolean>"
      when Float
        "<double>#{i}</double>"
      when Array
        array = "<array><data>"
        i.each {|n| array << "<value>#{make_xml_value(n)}</value>"}
        array << "</data></array>"

      when Hash
        struct = "<struct>"
        i.each_pair do |key, value|
          struct << "<member><name>#{key}</name><value>#{make_xml_value(value)}</value></member>"
        end
        struct << "</struct>"

      else
        raise "Invalid XMLRPC value. '#{i}' doesn't match any scalar types..."
      end

    end
  end



  class Parser
    require 'rexml/document'
    
    attr_reader :response

    def initialize(xml_response=nil)
      self.parse xml_response if xml_response
    end

    def parse (response)
      @xml_response = REXML::Document.new response
      @response     = Array.new

      if @xml_response.elements['methodResponse/fault']
        @response << :fault
        
        @xml_response.elements['methodResponse/fault/value'].each do |fault_struct| 
          parse_value fault_struct
        end

      elsif @xml_response.elements.each 'methodResponse/params/param/value' do |i|

          if i.has_elements?
            i.elements.each {|value| self.parse_value value}
          
          else
            if i.has_text?
              @response << i.text
            else
              @response << nil
            end
          end
      end

      else
        raise "Invalid XMLRPC response: #{@xml_response[256]}..."
      end
    end

    def parse_value (value, response=nil)
      response = response || @response  # When the value is a list, we do not want to effect the response list
      value_type = value.name

      case value_type

      when 'string'
        response << value.text
      when 'int', 'i4'
        response << value.text.to_i
      when 'double'
        response << value.text.to_f
      when 'boolean'

        if value.text == '0'
          response << false
        elsif value.text == '1'
          response << true
        else
          response << :invalid_boolean
        end
      when 'array'
        array = Array.new
        value.elements.each 'data/value/*' {|i| parse_value (i, array)}
        response << array
      when 'struct'
        hash_keys   = Array.new
        hash_values = Array.new

        value.elements.each 'member/name' {|i| hash_keys << i.text}

        # Pandora backend appears to be written in java. And xml response does not seem to adhear to
        # XMLRPC spec. For example, pandora may return a struct in this form 
        #     <struct>
        #       <member>
        #         <name>soda_pop</name>
        #         <value>SUGAR</value>      <---- Text in '<value>' will be stored as a string
        #         </member>
        #
        #       <member>
        #         <name>someToken</name>
        #         </value>         <------------- Empty values will be represented as 'nil'
        #         </member>
        #      </struct>
        value.elements.each 'member/value' do |i|
          if i.has_text?
            hash_values << i.text
          elsif i.has_elements?
            i.elements.each {|n| parse_value(n, hash_values)}
          else
            hash_values << nil
          end
        end

        h = Hash.new
        hash_keys.zip(hash_values).each {|i| h[i.first] = i.last}
        response << h

      else
        raise  "[!] Could not parse scalar type '#{value_type}' from xml"
      end
    end

  end

end
