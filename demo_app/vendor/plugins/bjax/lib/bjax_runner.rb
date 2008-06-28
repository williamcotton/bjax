def javascript_call(key, json)
  "Bjax.__job_responder[#{key}].onSuccess(#{json});"
end

def render(input)
  Juggernaut.send_to_channels(javascript_call(@params["key"], input[:bjax].to_json), [@juggernaut_channel])
end

# pass in the JSON object with the options and the bjax source to eval...
# when it gets to the render method at the end, have it format a proper Juggernaut.send_to_channels

@params = ActiveSupport::JSON.decode(ARGV[0])
@juggernaut_channel = ARGV[2]

eval("params = @params\n" + ARGV[1].unpack("m")[0])