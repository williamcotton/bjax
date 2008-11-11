begin
  def javascript_status_update_call(key, message)
    "Bjax.__job_responder[#{key}].onStatusUpdate(#{message});"
  end

  def javascript_response_call(key, json)
    "Bjax.__job_responder[#{key}].onSuccess(#{json});"
  end
  
  def javascript_error_response_call(key, json)
    "Bjax.__job_responder[#{key}].onRemoteError(#{json});"
  end

  def render(input)
    if input[:bjax]
      puts "\x01%%%%\x01BJ\x01%%%%\x01" + input[:bjax].to_json + "\x01%%%%\x01BJ\x01%%%%\x01"
      Juggernaut.send_to_channels(javascript_response_call(@params["key"], input[:bjax].to_json), [@juggernaut_channel])
    end
    if input[:bjax_status_update]
      puts "%%%%BJ-status-updates%%%%" + input[:bjax_status_update].to_json + "%%%%BJ-status-updates%%%%"
      Juggernaut.send_to_channels(javascript_status_update_call(@params["key"], input[:bjax_status_update].to_json), [@juggernaut_channel])
    end
  rescue
  end

  @params = Marshal.load(ARGV[0].unpack("m")[0])
  @juggernaut_channel = ARGV[2]

  eval("params = @params\n" + ARGV[1].unpack("m")[0])

rescue
  puts "%%%%BJ-error%%%%" + { :error => $! }.to_json + "%%%%BJ-error%%%%"
  Juggernaut.send_to_channels(javascript_error_response_call(@params["key"], { :error => $! }.to_json), [@juggernaut_channel])
end