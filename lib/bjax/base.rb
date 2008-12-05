# Bjax



class Bjax
  
  def initialize(options, &block)
    @options = options
    @marshal_params = [Marshal.dump(options[:params])].pack("m").gsub("\n","")
    @b64source = [Marshal.dump(block)].pack("m").gsub("\n","")
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
    job_task = "./script/runner " + BJAX_DIR + "/bjax/bjax_runner.rb \"#{@marshal_params}\" \"#{@b64source}\" \"#{@juggernaut_channel}\""
    @job = Bj.submit job_task
    @id = "bj:" + @job.first.bj_job_id.to_s
  end
  
  def workling_call_remote
    job_task = BjaxWorker.async_remote_runner(:b64source => @b64source, :juggernaut_channel => @juggernaut_channel, :marshal_params => @marshal_params)
    @id = @job = "workling:" + job_task
  end
  
end