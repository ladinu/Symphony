module RawXML
  def int_xml
    '<?xml version="1.0" ?><methodCall><methodName>sample.Method</methodName><params><param><value><int>1</int></value></param></params></methodCall>'
  end

  def string_xml
    '<?xml version="1.0" ?><methodCall><methodName>sample.Method</methodName><params><param><value><string>str</string></value></param></params></methodCall>'
  end

  def double_xml
    '<?xml version="1.0" ?><methodCall><methodName>sample.Method</methodName><params><param><value><double>1.0</double></value></param></params></methodCall>'
  end

  def bool_t_xml
    '<?xml version="1.0" ?><methodCall><methodName>sample.Method</methodName><params><param><value><boolean>1</boolean></value></param></params></methodCall>'
  end

  def bool_f_xml
    '<?xml version="1.0" ?><methodCall><methodName>sample.Method</methodName><params><param><value><boolean>0</boolean></value></param></params></methodCall>'
  end

  def struct_xml
    '<?xml version="1.0" ?><methodCall><methodName>sample.Method</methodName><params><param><value><struct><member><name>string</name><value><int>1</int></value></member></struct></value></param></params></methodCall>'
  end

  def array_xml
    '<?xml version="1.0" ?><methodCall><methodName>sample.Method</methodName><params><param><value><array><data><value><int>1</int></value><value><string>str</string></value><value><struct><member><name>1</name><value><double>1.0</double></value></member></struct></value></data></array></value></param></params></methodCall>'
  end

  def base64_xml
    '<?xml version="1.0" ?><methodCall><methodName>sample.Method</methodName><params><param><value><base64>QXNk\n</base64></value></param></params></methodCall>'
  end

  def date_time_xml
    '<?xml version="1.0" ?><methodCall><methodName>sample.Method</methodName><params><param><value><dateTime.iso8601>19930203T04:05:06</dateTime.iso8601></value></param></params></methodCall>'
  end

  def all_scalar_xml
    '<?xml version="1.0" ?><methodCall><methodName>sample.Method</methodName><params><param><value><array><data><value><int>1</int></value><value><double>1.0</double></value><value><boolean>1</boolean></value><value><boolean>0</boolean></value><value><string>the quick simple string</string></value><value><struct><member><name>soda</name><value><string>pop</string></value></member></struct></value></data></array></value></param></params></methodCall>'
  end

end
