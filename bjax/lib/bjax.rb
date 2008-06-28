# Bjax

Mime::Type.register_alias "application/x-www-form-urlencoded-bjax", :bjax
BJAX_DIR = File.dirname(__FILE__)

class Bjax < Sproc
  
  def initialize(options, &block)
    @options = options
    @json_params = options[:params].to_json.gsub('"',"'")
    @juggernaut_channel = options[:juggernaut_channel]
    @key = options[:params][:key]
    @block = block
    super()
    call_remote
  end
  
  attr_accessor :options, :json_params, :id, :key
  
  def call_remote
    case @options[:host]
    when :localhost
      call_remote_on_localhost
    end
  end
  
  private
  
  def call_remote_on_localhost
    b64source = [self.source].pack("m").gsub("\n","")
    
    job_task = "./script/runner " + BJAX_DIR + "/bjax_runner.rb \"#{@json_params}\" \"#{b64source}\" \"#{@juggernaut_channel}\""
    
    @job = Bj.submit job_task
    @id = @job.first.bj_job_id
  end
  
end