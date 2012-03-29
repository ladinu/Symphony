require 'test/unit'
require '../symphony_core/xmlrpc.rb'
#require '../symphony_request'
require '../symphony_core/Blowfish'
require 'raw_xml'
require 'parsed_xml_values'

class TestXMLRPC < Test::Unit::TestCase
  include RawXML, ParsedXML

  def test_valid_methodName
    rpc = XMLRPC::Call.new("sample.Method", 1)
    assert_equal(true, rpc.valid_method_name?("sample.ifso:/39_A"))
  end

  def test_invalid_methodName
    rpc = XMLRPC::Call.new("sample.Method", 1)
    assert_equal(false, rpc.valid_method_name?('!@#$%;'))
  end

  def test_rpc_static_values

    rpc = XMLRPC::Call.new

    rpc.new_call("sample.Method", 1)
    assert_equal(self.int_xml, rpc.xml)

    rpc.new_call('sample.Method', 'str')
    assert_equal(self.string_xml, rpc.xml)

    rpc.new_call('sample.Method', 1.0)
    assert_equal(self.double_xml, rpc.xml)

    rpc.new_call('sample.Method', true)
    assert_equal(self.bool_t_xml, rpc.xml)

    rpc.new_call('sample.Method', false)
    assert_equal(self.bool_f_xml, rpc.xml)

    rpc.new_call('sample.Method', {'string' => 1})
    assert_equal(self.struct_xml, rpc.xml)

    rpc.new_call('sample.Method', [1, 'str', {'1' => 1.0}])
    assert_equal(self.array_xml, rpc.xml)

    rpc.new_call('sample.Method', [1, 1.0, true, false, "the quick simple string", {'soda'=>'pop'}])
    assert_equal(self.all_scalar_xml, rpc.xml)
  end

  def test_pandora_rpc_method_response
    f = File.new 'pandora_methodResponse.xml', 'r'
    @@parser = XMLRPC::Parser.new
    @@parser.parse f

    assert_equal(@@parser.response.to_s, self.pandora_response)
  end

  def test_rpc_method_response
    f = File.new 'methodResponse.xml', 'r'
    @@parser.parse f

    assert_equal(@@parser.response.to_s, self.method_response)
  end

  def test_rpc_fault_response
    f = File.new 'faultResponse.xml', 'r'
    @@parser.parse f

    assert_equal(@@parser.response.to_s, self.fault_response)
  end

    

end

