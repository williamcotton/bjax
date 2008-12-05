# Bjax

Mime::Type.register_alias "application/x-www-form-urlencoded-bjax", :bjax
BJAX_DIR = File.dirname(__FILE__)

require 'bjax/base'
require 'bjax/worker'
require 'bjax/bjax_job_polling_controller'