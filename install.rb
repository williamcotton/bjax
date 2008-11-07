require 'fileutils'

here = File.dirname(__FILE__)
there = defined?(RAILS_ROOT) ? RAILS_ROOT : "#{here}/../../.."

puts "Installing Bjax..."
FileUtils.cp("#{here}/media/bjax.js", "#{there}/public/javascripts/")

puts "Bjax has been successfully installed."
puts IO.read(File.join(File.dirname(__FILE__), 'README'))