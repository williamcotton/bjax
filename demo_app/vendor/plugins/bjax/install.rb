# Install hook code here

require 'fileutils'

here = File.dirname(__FILE__)
there = defined?(RAILS_ROOT) ? RAILS_ROOT : "#{here}/../../.."

puts "Installing Bjax..."
FileUtils.cp("#{here}/media/bjax.js", "#{there}/public/javascripts/")

puts "Bjax has been successfully installed."
puts
puts "Please refer to the readme file #{File.expand_path(here)}/README"