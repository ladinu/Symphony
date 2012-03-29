module ParsedXML
  def pandora_response
    "[{\"subscriptionDaysLeft\"=>\"\\n\", \"fbEmailHash\"=>\"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\", \"fbShareUserTokens\"=>nil, \"timeoutCredits\"=>\"\\n\", \"listenerId\"=>\"000000000\", \"gender\"=>\"AAAA\", \"fullName\"=>nil, \"bookmarkUrl\"=>\"http://www.pandora.com/people/foobar\"}]"
  end

  def method_response
    "[30, 53, false, true, 3.1415, \"asdasd\", {\"lowerBound\"=>18, \"upperBound\"=>139}, [1, \"asd\"]]"
  end

  def fault_response
    "[:fault, {\"faultString\"=>\"com.savagebeast.radio.api.protocol.xmlrpc.RadioXmlRpcException: method not found: listner.authenticateListner\", \"faultCode\"=>14}]"
  end
end

