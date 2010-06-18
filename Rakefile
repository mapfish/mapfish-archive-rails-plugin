require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the mapfish plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the mapfish plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Mapfish'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "mapfish"
    gemspec.summary = "Mapfish server plugin for Ruby on Rails"
    gemspec.description = "MapFish is a flexible and complete framework for building rich web-mapping applications. Homepage: mapfish.org"
    gemspec.email = "pka@sourcepole.ch"
    gemspec.homepage = "http://mapfish.org/doc/implementations/rails.html"
    gemspec.authors = ["Pirmin Kalberer"]
    gemspec.add_dependency("spatial_adapter")
    gemspec.add_dependency("GeoRuby")
    gemspec.add_dependency("POpen4", ">= 0.1.4")
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end
