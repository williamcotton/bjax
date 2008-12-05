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