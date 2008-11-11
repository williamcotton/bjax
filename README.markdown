# Bjax

Bjax allows for asynchronous Javascript to trigger jobs to run off of the main Rails application with updates being sent back to the client. The job queue utilizes Workling and Starling, falling back on BackgroundJob if those services are not available. It uses Juggernaut to inform the client of any status updates and return values from the job, falling back on Ajax polling if the service is unavailable.

Please note that this is alpha software! It is currently stable, functional, and in use in production at http://bleacherreport.com in our blog importing wizard. However, the implementation of it is not very pretty... another quick and dirty hack job with an emphasis on the results it has brought!

## Why Bjax?

Bjax allows you to move time or processor intensive tasks off of your Rails application while alerting the client of any status updates and information to be returned. Combining Bjax with clusters of Workling, Starling, and Juggernaut servers allows your Rails application to scale, regardless of what kinds of heavy-duty lifting your Rails application is doing, from image manipulation, to video processing, RSS feed importing, scraping of 3rd-party web sites, or whatever other tasks you can think up that would normally seem insane from a user experience and deployment standpoint.

## Installing Bjax

Get started with Bjax by installing the plugin:

    script/plugin install git://github.com/williamcotton/bjax.git

## Additional Requirements

Bjax is currently designed around Workling, Starling, Juggernaut, and BackgroundJob.

### Workling and Starling

While [Workling](http://github.com/purzelrakete/workling/tree/master) and [Starling](http://github.com/starling/starling/tree/master) are not required and it will degrade to work with BackgroundJob, it is very much recommended. Please install the Workling plugin and browse the README for further instructions related to setting up Starling.

	script/plugin install git://github.com/purzelrakete/workling.git
	
There is a very good introduction to both of these technologies in the [Workling and Starling Railscast](http://railscasts.com/episodes/128-starling-and-workling).
	
### BackgroundJob

[BackgroundJob](http://codeforpeople.rubyforge.org/svn/bj/trunk/README) is required, although it is not the default job queue. It is used for redundancy.

    ./script/plugin install http://codeforpeople.rubyforge.org/svn/rails/plugins/bj
    ./script/bj setup

### Juggernaut

[Juggernaut](http://juggernaut.rubyforge.org/) is not required, but it is highly recommended for push notifications. If it is not installed, Bjax will fall back on Ajax polling.

	script/plugin install http://juggernaut.rubyforge.org/svn/trunk/juggernaut
	
### Prototype

Currently, Bjax is based on the [Prototype](http://www.prototypejs.org/) Javascript library.
	
## Using Bjax

### View Code

	<%= juggernaut(:channels => ["bjax_" + @current_user.id.to_s]) %>

	<script type="text/javascript">

		getItems = function(page_id) {
			var attributes = {};
			attributes.page_id = page_id;
			
			new Bjax.Request("/some_controller/get_items", {
				parameters: attributes,
				onSuccess: function(results) { getItemResults(results) },
				onStatusUpdate: function(message) { getItemStatusUpdate(message) }
			});
		}
		
		getItemResults = function(results) {
			if (results.status) {
				items.each(function(item) {
					alert(item);
				});
			}
		}
		
		getItemStatusUpdate = function(message) {
			alert(message);
		}
	
	</script>

### Controller Code

	def get_items
	  respond_to do |format|
	    format.bjax {
		
	      juggernaut_channel = "bjax_" + @current_user.id.to_s
	      bj = Bjax.new(:juggernaut_channel => juggernaut_channel, :params => params) do
	  	    
	        render :bjax_status_update => "Getting Page"
	        page = Page.find(params["page_id"])
	        
	        render :bjax_status_update => "Computing Items"
	        page.compute_items
	
	        render :bjax_status_update => "Updating Client"
	
	        if page.items_computed?
	          status = true
	        else
	          status = false
	        end
	
	        render :bjax => { :status => status, :items => page.items }
	      end
	
	      render :json => bj.id
	    }
	  end
	end
	
### routes.rb

	map.connect "/bjax_job_polling/:action/:id", :controller => 'bjax_job_polling'
	
### Seriously!?

Yes! That's it. As long as you have Juggernaut, Starling, Workling, and BackgroundJob properly configured and running, Bjax handles the rest.

That code block is passed off to the Worklings regardless of where they are... in most deployment situations the code will likely be run on a completely different slice. It does this by using a serialized Proc.

### Usage Notes!

Bjax currently has issues with using "render :bjax" more than once in a code block. I recommend that the last line of the code block contains the "render :bjax" method call.

You cannot create the code block as a proc or lambda and use that to call Bjax.new. You MUST pass code as a block during the creation of a Bjax instance.

In order for Bjax to fall back on polling, you MUST return the id of the Bjax instance, ie, render :json => bj.id

## Serialized Procs? WTF are you thinking?!

I **REALLY** like the idea of serialized Procs. While RPC, SOAP, and other service oriented architectures are nice, they don't allow trusted resources to integrate is such a seamless way. Also, possibilities are limited to the APIs that each site offer up. With serialized Procs, code written in one environment could be executed in another environment, be it another process, or another server, with no limitations on what could be done, other than the scope it is run in.

## Future Development Ideas

Perhaps some documentation? :)

The library needs to be better organized with proper namespacing and separation of code.

Better integration and support for other background job processors, message queues, and Comet-style persistent client connections. (I'm looking at you, XMPP-BOSH and XMPP-SEP)

Support for additional Javascript libraries.

Make the serialized Proc code way more robust.

---

Copyright (c) 2008 William Cotton, released under the MIT license
