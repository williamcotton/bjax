var Bjax = new Object();

Bjax.__job_responder = {};

Bjax.Request = Class.create({
	initialize: function(options) {
	    this.options = {
			method: 'get',
			contentType: 'application/x-www-form-urlencoded-bjax'
	    };
	    Object.extend(this.options, options || { });
		this.key = Math.random().toString().slice(2,-1).replace("0","");
		this.options.parameters.key = this.key;
		var o = {};
		o.onSuccess = this.options.onSuccess;
		Bjax.__job_responder[this.key] = o;
		this._request();
	},
	
	_request: function() {
		var that = this;
		
		new Ajax.Request(this.options.url, {
			method: this.options.method,
			parameters: this.options.parameters,
			contentType: this.options.contentType,
			onSuccess: function(transport) { that._response(transport); },
			onFailure: function() {  },
			onLoading: function() {  }
		});
	},
	
	_response: function(transport) {
		this.transport = transport;
		this.response = eval( "(" + transport.responseText + ")" );
		Bjax.__job_responder[this.key].BJ = this.response;
	}
});