# This XMLRPC module is easy to use and liteweight and it is written in ≈200 lines of [Ruby][rb]
# code. I decided to write this module for the following reasons:
#
#
# First, I wanted to learn Ruby. I'm working on a MacOS specific port (named [Symphony][sm]) of 
# [pianobar][pb] written in [MacRuby][mr]. Because [Pandora][pn] use XMLRPC, I decided to write
# this module to get fimiliar with XMLRPC and Ruby.
#
# Second, I needed a simple XMLRPC library. Ruby's default XMlRPC library is hard to use and does
# not offer easy access to internal XMLRPC data. Also Ruby's default XMLRPC library is a good choice
# beacuse XMLRPC calls to Pandora servers need to be encrypted and responses to be decrypted.


#[pb]: http://6xq.net/projects/pianobar/
#[mr]: http://www.macruby.org
#[pn]: http://www.pandora.com
#[sm]: https://github.com/ladinu/Symphony
#[rb]: http://www.ruby-lang.org/

# ###License/Credits
# This software is released under the [MIT] (http://www.opensource.org/licenses/MIT) License.
# Please reffer to the [license](https://github.com/ladinu/Symphony/blob/master/symphony_core/license.txt) 
# located at github. This documentation is generated using [Rocco](http://rtomayko.github.com/rocco/).


# ###XMLRPC Overview
#
# If you are not familiar with XMLRPC, please read the [XMLRPC specifications](http://xmlrpc.scripting.com/spec.html).
#
# *XMLRPC* stands for *XML Remote Procedure Call*. XMLRPC invoke methods on remote servers. The string
# enclosed in `<methodName>` tag is called the method name. The strings enclosed in `<param>` tags are the data to the method
# call.
#
# The following data types/structures can be used in a XMLRPC request:
#
#   - integers
#   - strings
#   - booleans
#   - doubles/floats
#   - date/time (encoded in [iso8601](http://en.wikipedia.org/wiki/ISO_8601))
#   - base64 (for binary data)
#   - arrays
#   - structs
#

# This is an example of a XMLRPC request.
#
#   `<?xml version=\"1.0\" ?>
#   <methodCall>
#   <methodName>listener.authenticateListener</methodName>
#     <params>
#        <param><value><string>john.doe@mail.com</string></value></param>
#        <param><value><string>password123</string></value></param>
#     </params>
#   </methodCall>`
#
# The string *listener.authenticateListener* is the method name. String *john.doe@mail.com* and string *password123* are the
# parameters.


# ###XMLRPC Module Documentation


# This XMLRPC module has two classes, `Call` and `Parser`. They create XMLRPC requests and parse XMLRPC responses. `Parser` will parse 
# XMLRPC responses to Ruby data structures/types.
module XMLRPC

  # ####Call
  # Call object has one read-only accessor `@xml`. `@xml` holds XMLRPC request string.
  class Call
    attr_reader :xml

    # `new_call(method, *params)` create a XMLRPC request string. Argument `*param` is optional. `*` is used in `new_call` because 
    # a XMLRPC request can have multiple parameters. If `*param` is provided, `*param` must contain XMLRPC supported data 
    # types/structures.
    #
    # For example:
    #
    #       Call.new_call('user.athenticate', 'username', 'passwd')
    #       Call.new_call('user.reply', 1, [1, 2, 'foo'], "string")
    #       Call.new_call('list.sync') # A request without parameters
    #
    def new_call(method, *params)

      if valid_method_name? method
        @method = method
        self.make_xml params
      else
        raise  "[!] Method name '#{method}' is an invalid XMLRPC method name"
      end
    end

    # `valid_method_name?(methodName)` check for correct XMLRPC method names (see *Payload Format* section at
    # <http://xmlrpc.scripting.com/spec.html>).
    def valid_method_name?(methodName)
      if methodName.class == String

        # For examples:
        #
        #     Call.valid_method_name? 'sample.method'     # => true
	      #     Call.valid_method_name? 'sAmPLe._meth0d:9/' # => true
        #
        #     Call.valid_method_name? 'sample-method'     # => false
	      #     Call.valid_method_name? 's#ample.method'    # => false
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

    # Method `make_xml(params)` create the XMLRPC request body. `make_xml_value(i)` is called for every item in `params`.
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
      
    # First, `make_xml_value(i)` check the data type of `i`. Then `i` is enclosed in appropriate data tags. If data type of
    # `i` is a *hash* or an *array*, FIXME: recursion is used to construct the data tags.
    #
    # For example:
    # 
    #     Call.make_xml_value 'some_str' # =>  "<string>some_str</string>"
    #     Call.make_xml_value 3.14159    # => "<double>3.14159</double>"
    #     Call.make_xml_value true       # => "<boolean>1</boolean>"
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



  # ####Parser
  # ####Revision 2: B
  # `Parser` use XML parsing module [REXML][rx] and language [XPath][xp] to parse XMLRPC responses. XMLRPC response data is converted into Ruby
  # data types/structures.
  #
  # Note that parsing large XMLRPC responses are very time consuming. This is beacuse REXML is written in pure Ruby.
  # I will implement a fast XML parsing library in future versions of this XMLRPC module.
  #
  # [rx]: http://www.germane-software.com/software/rexml/
  # [xp]: http://www.w3schools.com/xpath/xpath_examples.asp
  class Parser
    require 'rexml/document'
    
    # `Parser` has one public atribute named `@response`. `@response` is an array. Parsed XMLRPC values are apended to `@response`. If
    # XMLRPC response type is *fault*, then `:fault` symbol is added to `@response` as the first item.
    attr_reader :response

    # `parse` method is called when `xml_response` is provided.
    def initialize(xml_response=nil)
      self.parse xml_response if xml_response
    end

    # `parse` method take a XML string for input. `parse` method populate the array `@response` with Ruby data types/
    # structures. The item(s) in `@response` match the order of encoded data in the XMLRPC response.
    def parse (response)
      # `parse` method first create a REXML document by passing in `response` to `REXML::Document`.
      @xml_response = REXML::Document.new response
      @response     = Array.new

      # `parse` method checks for *fault* XMLRPC response by searching for the path `methodResponse/fault` in the REXML
      # document (see *Response format* section at <http://xmlrpc.scripting.com/spec.html>). If such path exist, 
      # then `parse` method will parse the *fault code* and *fault string* into a Ruby hash. Also, `:fault` symbol is added to `@response` 
      # as the first item.
      if @xml_response.elements['methodResponse/fault']
        @response << :fault
        
        @xml_response.elements['methodResponse/fault/value'].each do |fault_struct| 
          parse_value fault_struct
        end

      # If a fault XMLRPC response was not found, then `parse` method looks for the path
      # `methodResponse/params/param/value`. If such path exist, then `parse` method continue parsing 
      # XMLRPC response values. `parse_value` method is called for each scalar values such as string, int, 
      # bool etc.
      elsif @xml_response.elements.each 'methodResponse/params/param/value' do |i|

          if i.has_elements?
            i.elements.each {|value| self.parse_value value}
          
          # If XMLRPC response values are not enclosed in any tags, `parse` method add `nil` or actual text value to `@response`.
          #
          # For example,
          #
          #       <value>FOO</value> # text FOO will be added to @response
          #       <value></value>    # nil will be added to @response
          else
            if i.has_text?
              @response << i.text
            else
              @response << nil
            end
          end
      end

      # If path `methodResponse/params/param/value` does not exist, then `parse` method treat input string `response` as an invalid
      # XMLRPC response. `parse` method raise an exception when XMLRPC response is invalid. The exception diplay the first 256 characters
      # of the `response` string.
      else
        raise "Invalid XMLRPC response: #{@xml_response[256]}..."
      end
    end

    # `parse_value` method accept two values: `value` and `response` (where `response` is optional). `parse` method pass `value` which 
    # is a REXML data type.
    def parse_value (value, response=nil)

      # First, `parse_value` method checks if a diffrent `response` variable is given. If not, `parse_value` 
      # use the default `@response` variable. Then `parse_value` store `value` name in `value_type`. 
      # For example, if `value` was *\<double\>2.71828183\</double\>*, then `value_type` would be *double*.
      response = response || @response  # When the value is a list, we do not want to effect the response list
      value_type = value.name

      # `parse_value` use a case statement to check each possible XMLRPC data type. When a valid data type is found, `value`'s
      # text is converted to a Ruby data type/structure and appended to `response`. For example, 
      # if `value` is *\<double\>2.71828183\</double\>*, then `value` text *'2.71828183'* is converted to a 
      # float and appended to `response`.
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

      # ####Revision 2: A
      # `parse_value` method parse each item in `value` recursivly when `value` type is a XMLRPC *\<array\>*.
      # First, `parse_value` create a new array. Then `parse_value` call itself for each item in `value` like 
      # following: `parse_value(i, array)` where `i` is an item in the XMLRPC array and `array` is the newly crated array.
      #
      # Because the argument `array` is passed to `parse_value`, `parse_value` append parsed XMLRPC array items to
      # `array` variable (which will be appended to `@response` later).
      when 'array'
        array = Array.new
        value.elements.each 'data/value/*' {|i| parse_value (i, array)}
        response << array

      # `parse_value` method also parse XMLRPC *<struct\>* recursivly. XMLRPC structs are converted into Ruby hashes.
      # First, `parse_value` create two arrays named `hash_key` and `hash_values`. Then `hash_keys` is populated with 
      # each *'member/name'* of the XMLRPC struct. Then `hash_value` is populated with each *'member/value'* of the 
      # XMLRPC struct. 
      # 
      #
      # Some XMLRPC response servers do not adhear to XMLRPC specifications. To make `Parser` compatible with such
      # servers, the following is done: `nil` is inserted into `hash_values` when *\<value\>* is empty. Data in 
      # *\<value\>* tag is converted to text when *\<value\>* tag is not empty. Finally, `hash_values` and
      # `hash_keys` are zipped into a Ruby hash and appended to `response`.
      when 'struct'
        hash_keys   = Array.new
        hash_values = Array.new

        value.elements.each 'member/name' {|i| hash_keys << i.text}

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

      # If `value` does not match any XMLRPC data types this exception is raised.
      else
        raise  "[!] Could not parse scalar type '#{value_type}' from xml"
      end
    end

  end

end
