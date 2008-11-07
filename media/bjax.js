var Bjax = new Object();

Bjax.__job_responder = {};

Bjax.Request = Class.create({
	initialize: function(url, options) {
	    this.options = {
			method: 'get',
			contentType: 'application/x-www-form-urlencoded-bjax'
	    };
		this.url = url;
	    Object.extend(this.options, options || { });
		this.key = Math.random().toString().slice(2,-1).replace("0","");
		this.options.parameters.key = this.key;
		this.onServerError = this.options.onServerError;
		
		var o = {};
		o.onSuccess = this.options.onSuccess;
		o.onStatusUpdate = this.options.onStatusUpdate;
		o.onRemoteError = this.options.onRemoteError;
		o.bjax = this;
		
		this.onBackEndType = this.options.onBackEndType;
		
		Bjax.__job_responder[this.key] = o;
		
		this.responderObject = o;
		this._request();
		if (typeof(juggernaut) == "undefined" || !juggernaut.is_connected) {
			var that = this;
			this.statusChecker = new PeriodicalExecuter(function(pe){ that._checkStatus(true); }, 3 ); // TODO Change the polling time when it's a Bj job... it takes much longer!
		}
	},
	
	_checkStatus: function() {
		
		if (typeof(juggernaut) == "undefined" || !juggernaut.is_connected) {
		
			var url = '/bjax_job_polling/check_status/' + this.id;
			var that = this;
	
			new Ajax.Request(url, {
				method: 'get',
				onSuccess: function(transport) { that._checkStatusResults(transport); },
				onFailure: function() {
					that.statusChecker.stop();
					if (that.onServerError) {
						that.onServerError([["server", "might be having some difficulties."]]);
					}
				},
				onLoading: function() {  }
			});
		}

	},
	
	_checkStatusResults: function(transport) {
		var response = eval( "(" + transport.responseText + ")" );
		if (response) {
			if (response.statusUpdates) {
				response.statusUpdates.each(function(statusUpdate) {
					this.responderObject.onStatusUpdate(statusUpdate);
				}.bind(this));
			}
			if (response.results) {
				this.responderObject.onSuccess(response.results);
				this.statusChecker.stop();
			}
			if (response.remoteError) {
				this.responderObject.onRemoteError(response.remoteError);
				this.statusChecker.stop();
			}
		}
	},
	
	_request: function() {
		var that = this;
		
		new Ajax.Request(this.url, {
			method: this.options.method,
			parameters: this.options.parameters,
			contentType: this.options.contentType,
			onSuccess: function(transport) { that._response(transport); },
			onFailure: function() { 
				if (that.onServerError) {
					that.onServerError([["server", "is not responding."]]);
				}
			},
			onLoading: function() {  }
		});
	},
	
	_response: function(transport) {		
		this.transport = transport;
		this.response = transport.responseText;
		this.id = this.response;
		Bjax.__job_responder[this.key].BJ = this.response;
		if (this.onBackEndType) {
			this.onBackEndType(this.id);
		}
	}
});