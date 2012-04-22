# This XMLRPC module is a liteweight and easy to use `XMLRPC` module written in ≈200 lines of code. 
# I decided to write this module for the following reasons.
#
# I wanted to learn Ruby. I'm currently working on a MacOS specific port (named [Symphony][sm]) of 
# [pianobar][pb] written in [MacRuby][mr]. Because [Pandora][pn] use XMLRPC, I needed a lightweight 
# and easy to use XMLRPC library. What better way to learn Ruby than writing my own XMLRPC library?
#       
# I also needed an easy-to-use and lightweight XMLRPC library. Ruby's default XMLRPC client does not 
# offer easy access to XMLRPC data. Because XMLRPC calls to pandora servers needs to be encrypted, 
# trying to implement XMLRPC data encryption/decryption in default Ruby XMLRPC library is very 
# difficult.


#[pb]: http://6xq.net/projects/pianobar/
#[mr]: http://www.macruby.org
#[pn]: http://www.pandora.com
#[sm]: https://github.com/ladinu/Symphony

# ###License/Credits
# This software is released under the [MIT] (http://www.opensource.org/licenses/MIT) License.
# Please reffer to the [license](http://www.google.com) located at github. This documentation is generated
# using [Rocco](http://rtomayko.github.com/rocco/).


# ###XML Remote Procedure Call
#
# If you are not familiar with XMLRPC, please read the [XMLRPC specifications](http://xmlrpc.scripting.c# om/spec.html).
#
# Here is a quick overview:
#
#  *XMLRPC* stands for XML Remote Procedure Call. XMLRPC is usually used for invoking certain 
#  actions on a remote server by a client. In a XMLRPC request, the string enclosed in 
#  `<methodName>` tag is called the method name. Data enclosed in `<param>` tags are the parameters for 
#  the method call.
#
#  XMLRPC allows for eight data structures/types for parameters:
#
#   - integers
#   - strings
#   - booleans, 
#   - doubles/floats
#   - date/time (encoded in [iso8601](http://en.wikipedia.org/wiki/ISO_8601))
#   - base64 (for binary data)
#   - arrays
#   - structs
#

#The following is an example XMLRPC request where the method *listener.authenticateListener* is 
#invoked on a remote server given the parameters *john.doe@mail.com* and *password123*.

#   `<?xml version=\"1.0\" ?>
#   <methodCall>
#   <methodName>listener.authenticateListener</methodName>
#     <params>
#        <param><value><string>john.doe@mail.com</string></value></param>
#        <param><value><string>password123</string></value></param>
#     </params>
#   </methodCall>`


# ###XMLRPC Module Documentation

# The XMLRPC module has two classes, `Call` and `Parser`. They are responsible for creating XMLRPC 
# requests and parsing XMLRPC responses. `Parser` will parse XMLRPC responses to native ruby data structures/types.
module XMLRPC

  #Call object has only one read-only accessor `@xml`. `@xml` holds the actual XMLRPC request string.
  class Call
    attr_reader :xml

    # `new_call(method, *params)` creates an XMLRPC request when called with a method name and zero or more
    # param(s). Because an XMLRPC request can have multiple parameters, the `*` is used in `new_call`.
    #
    # For example,
    #
    #       Call.new_call('user.athenticate', 'username', 'passwd')
    #       Call.new_call('user.reply', 1, [1, 2, 'foo'], "string")
    #       Call.new_call('user.Auth') # A request without parameters
    #
    # The first argument to `new_call` must be the XMLRPC method name and the rest can be the XMLRPC supported
    # data types.
    def new_call(method, *params)

      if valid_method_name? method
        @method = method
        self.make_xml params
      else
        raise  "[!] Method name '#{method}' is an invalid XMLRPC method name"
      end
    end

    # `valid_method_name?(methodName)` checks for correct method names according to the XMLRPC specifications
    # (see *Payload Format* section at <http://xmlrpc.scripting.com/spec.html>). 
    # `valid_method_name(methodName)` is called by `new_call` before creating the XMLRPC request.

    def valid_method_name?(methodName)
      if methodName.class == String

        # A regular expression is used to match correct XMLRPC method names.
        #
        # For example,
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

    # `make_xml(params)` is called by `new_call`. `make_xml` method create the actual XMLRPC request.
    # `make_xml` calls `make_xml_value` for every value in `params`, and append the returning  value to `@xml`.
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
      
    # `make_xml_value(i)` checks the data type of `i` and retun the data type of `i` enclosed in XMLRPC data 
    # type/structure tag. When type if `i` is a *hash* or an *array*, `make_xml_value` use recursion to 
    # call it self to construct the *hash/array*.
    #
    # For example,
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



  # `Parser` object is responsible for parsing valid XMLRPC responses. When a XMLRPC response string is provided,   
  # `Parser` will parse the response into native Ruby data types/structures. `Parser` use the built-in Ruby XML 
  # parsing module [REXML][rx]. Most of the parsing is done using [XPath][xp].
  #
  # Note that parsing large XMLRPC responses are very resource intensive and time consuming. This is largley due
  # to the way in which REXML is written. In future versions of this XMLRPC module, an alternative XML parsing
  # library will be supported.
  #
  #
  # [rx]: http://www.germane-software.com/software/rexml/
  # [xp]: http://www.w3schools.com/xpath/xpath_examples.asp
  class Parser
    require 'rexml/document'
    
    # `Parser` has one public atribute named `@response`. `@response` hold the parsed XMLRPC response in native Ruby
    # data types/structures. The data type of `@response` is an array. Which will be populated later.
    attr_reader :response

    # If `xml_response` is ptovided `parse` method is called.
    def initialize(xml_response=nil)
      self.parse xml_response if xml_response
    end

    # `parse` method take a XML string for input. `parse` method populate the array `@response` with Ruby data types/
    # structures corresponding to the encoded data in the XMLRPC response.
    def parse (response)
      # `parse` method first create a REXML document by passing in `response`.
      @xml_response = REXML::Document.new response
      @response     = Array.new

      # `parse` checks for fault XMLRPC response by searching for the path `methodResponse/fault` in the REXML
      # document (see *Response format* section at <http://xmlrpc.scripting.com/spec.html>). If such path exist, 
      # then `parse` method will parse the fault code and fault string into a Ruby hash. Also, `:fault` symbol will
      # be added to `@response` as the first item.
      if @xml_response.elements['methodResponse/fault']
        @response << :fault
        
        @xml_response.elements['methodResponse/fault/value'].each do |fault_struct| 
          parse_value fault_struct
        end

      # If a fault XMLRPC response was not found, then `parse` method looks for the path
      # `methodResponse/params/param/value`. If such path exist, then `parse` method continues on to parsing 
      # XMLRPC response values. `parse_value` method is called for parsing each scalar values such as string, int, 
      # bool etc.
      elsif @xml_response.elements.each 'methodResponse/params/param/value' do |i|

          if i.has_elements?
            i.elements.each {|value| self.parse_value value}
          
          # If a XMLRPC response value is not enclosed in any tags, `nil` or the actual text of value will be added
          # to `@response`.
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

      # If path `methodResponse/params/param/value` does not exist, then the input string `response` is an invalid
      # XMLRPC response. `parse` method raise an exception which display the first 256 characters of the `response` 
      # string.
      else
        raise "Invalid XMLRPC response: #{@xml_response[256]}..."
      end
    end

    # `parse_value` method accept two values: `value` and `response` (where `response` is optional). `value` is a
    # REXML data type passed from `parse` method.
    def parse_value (value, response=nil)

      # Fist, `parse_value` method checks if an alternative `response` variable is passed. If not, default 
      # `@response` will be used. Then `parse_value` store the name of `value` in `value_type`. 
      # For example, if `value` was *\<double\>2.71828183\</double\>*, then `value_type` would be *double*.
      response = response || @response  # When the value is a list, we do not want to effect the response list
      value_type = value.name

      # `parse_value` use a case statement to check for each possible XMLRPC data types. When a valid data type is
      # encountered, `value`'s text is converted to a Ruby data type and appended to `response`. For example, 
      # if `value` was *\<double\>2.71828183\</double\>*, then `value` text *'2.71828183'* would be converted to a 
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

      # When `value` is a XMLRPC *\<array\>* type, recursion is used to parse each item in the XMLRPC array. First
      # a new array is created. Then, for each item in `value`, `parse_value` is called like following:
      #
      # `parse_value(i, array)` where `i` is an item in the XMLRPC array and `array` is the newly crated array. 
      # Because the second argument `array` is passed, `parse_value` will append parsed items in the XMLRPC array 
      # into the `array` variable (which will be appended to `@response` eventually).
      when 'array'
        array = Array.new
        value.elements.each 'data/value/*' {|i| parse_value (i, array)}
        response << array

      # When `value` is a XMLRPC *\<struct\>* type, recursion is again used to parse XMLRPC struct type to a native
      # Ruby hash. First two arrays are created, `hash_key` and `hash_values`. Then `hash_keys` is populated with 
      # each *'member/name'* of the XMLRPC struct. Then `hash_value` is populated with each *'member/value'* of the 
      # XMLRPC struct. 
      # 
      # Because some XMLRPC response servers does not strictly adhere to XMLRPC specifications, extra work is done 
      # to make `Parser` compatible with such implementations. When the *\<value\>* tag is empty, `nil` is inserted
      # into `hash_values`. When *\<value\>* tag is not empty, the data enclosed in *\<value\>* tag is treated as a
      # plain string. Finally, the two arrays, `hash_values` and `hash_keys` is zipped into a Ruby hash an appended
      # to `response`.
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

      # If `value` does not match any XMLRPC data types this exception will be raised.
      else
        raise  "[!] Could not parse scalar type '#{value_type}' from xml"
      end
    end

  end

end
