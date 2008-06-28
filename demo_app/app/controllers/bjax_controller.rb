class BjaxController < ApplicationController
  
  skip_before_filter :verify_authenticity_token 
  
  def index
    
  end
  
  def bjax_action
    respond_to do |format|
      format.bjax {
        juggernaut_channel = "user_123"
        bj = Bjax.new(:host => :localhost, :juggernaut_channel => juggernaut_channel, :params => params) do
          # BJAX Code
          m = params["article_id"].to_i
          x = 1
          while x <= 100
            puts m*m*x
            x = x+1
          end
          render :bjax => { :number => m*m*x, :message => "hey hey" }
          
        end

        render :text => bj.id

      }
    end
  end
  
end