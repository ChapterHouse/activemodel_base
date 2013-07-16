require "bundler/gem_tasks"
require "rspec/core/rake_task"
require 'rdoc/task'

RSpec::Core::RakeTask.new

task :default => :spec
task :test => :spec

RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.main = 'README.md'
  rdoc.rdoc_files.include 'README.md', "lib/**/*\.rb"

  rdoc.options << '--line-numbers'
end

