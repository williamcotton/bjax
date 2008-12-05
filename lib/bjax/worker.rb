if Workling
  if Workling::Starling.config
    Workling::Starling.config[:listeners] = {} unless Workling::Starling.config[:listeners]
    Workling::Starling.config[:listeners]["BjaxWorker"] = {"sleep_time" => 0.5}
  end
  
  class BjaxWorker < Workling::Base
    
    def test_connection(options)
      Workling.return.set(options[:uid], "testing")
    end
    
    def remote_runner(options)
      @uid = options[:uid]
      params = @params = Marshal.load(options[:marshal_params].unpack("m")[0])
      @juggernaut_channel = options[:juggernaut_channel] 
      Marshal.load(options[:b64source].unpack("m")[0]).call
    rescue
      Workling.return.set(@uid + "-error", { :error => $! }.to_json)
      Juggernaut.send_to_channels(javascript_error_response_call(@params["key"], { :error => $! }.to_json), [@juggernaut_channel])
    end
    
    private
    
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
        Workling.return.set(@uid, input[:bjax].to_json)
        Juggernaut.send_to_channels(javascript_response_call(@params["key"], input[:bjax].to_json), [@juggernaut_channel])
      end
      if input[:bjax_status_update]
        Workling.return.set(@uid + "-status", input[:bjax_status_update].to_json)
        Juggernaut.send_to_channels(javascript_status_update_call(@params["key"], input[:bjax_status_update].to_json), [@juggernaut_channel])
      end
    rescue
    end
    
  end
end