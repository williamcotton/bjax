# Bjax

Mime::Type.register_alias "application/x-www-form-urlencoded-bjax", :bjax
BJAX_DIR = File.dirname(__FILE__)

class Bjax < Sproc
  
  def initialize(options, &block)
    @options = options
    @marshal_params = [Marshal.dump(options[:params])].pack("m").gsub("\n","")
    @b64source = [self.source].pack("m").gsub("\n","")
    @juggernaut_channel = options[:juggernaut_channel]
    @key = options[:params][:key]
    @block = block
    super()
    call_remote
  end
  
  attr_accessor :options, :marshal_params, :id, :key
  
  def call_remote
    if Bjax.starling_available? && Bjax.workling_available?
      workling_call_remote
    else
      bj_call_remote_on_localhost
    end
  rescue
    bj_call_remote_on_localhost
  end
  
  private
  
  def self.starling_available?
    test = MemCache.new(Workling::Starling.config[:listens_on])
    test.set("testing","testing")
    return true
  rescue
    return false
  end
  
  def self.workling_available?
    # This could be better somehow... it adds an additional 0.5 second delay, but it is more robust...
    
    job_task = BjaxWorker.async_test_connection(:testing => "testing")
    sleep 0.5
    if Workling.return.get(job_task)
      return true
    else
      return false
    end
  rescue
    return false
  end
  
  # TODO check that juggernaut should be called... it should be passed in from the client/javascript,
  # that way, it won't result in a situation where messages are passed multiple times, if the client
  # calls Bjax requests before juggernaut has loaded on the page.
  
  def bj_call_remote_on_localhost
    job_task = "./script/runner " + BJAX_DIR + "/bj_runner.rb \"#{@marshal_params}\" \"#{@b64source}\" \"#{@juggernaut_channel}\""
    @job = Bj.submit job_task
    @id = "bj:" + @job.first.bj_job_id.to_s
  end
  
  def workling_call_remote
    job_task = BjaxWorker.async_remote_runner(:b64source => @b64source, :juggernaut_channel => @juggernaut_channel, :marshal_params => @marshal_params)
    @id = @job = "workling:" + job_task
  end
  
end

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
      @params = Marshal.load(options[:marshal_params].unpack("m")[0])
      @juggernaut_channel = options[:juggernaut_channel]

      eval("params = @params\n" + options[:b64source].unpack("m")[0])
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

class BjaxJobPollingController < ActionController::Base
  
  skip_before_filter :verify_authenticity_token
  layout nil
  session :off
  
  def check_status
    job_type = params[:id].split(":")[0]
    status_updates = []
    
    if job_type == "workling"
      workling_id = params[:id].split("workling:")[1]
      results = Workling.return.get(workling_id)
      while status_update = Workling.return.get(workling_id + "-status")
        status_updates << status_update
      end
      error = Workling.return.get(workling_id + "-error")
    elsif job_type == "bj"
      bj_id = params[:id].split(":").last.to_i
      job = Bj::Table::Job.find(bj_id)
      if job.state == "finished"
        results = job.stdout.split("\x01%%%%\x01BJ\x01%%%%\x01")[1] 
        m = "%%%%BJ-status-updates%%%%"
        status_updates = job.stdout.scan(/#{m}.*#{m}/).collect {|e| ActiveSupport::JSON.decode(e.gsub(m,"")) }
        er = "%%%%BJ-error%%%%"
        error = job.stdout.scan(/#{er}.*#{er}/).collect {|e| ActiveSupport::JSON.decode(e.gsub(m,"")) }
      end
    end
    
    output = {}
    output["results"] = ActiveSupport::JSON.decode(results) if results
    output["statusUpdates"] = status_updates if status_updates
    output["remoteError"] = error if error
    
    
    if results || !status_updates.empty?
      render :json => output
    else
      render :json => "false"
    end
      
  end
  
end

# class ActionController::Routing::RouteSet 
#   def draw 
#     clear! 
#     mapper = Mapper.new(self) 
#     add_bjax_routes(mapper) 
#     yield mapper
#     named_routes.install 
#   end 
#   def add_bjax_routes(mapper) 
#     mapper.connect "/bjax_job_polling/:action/:id", :controller => 'bjax_job_polling'
#   end 
# end