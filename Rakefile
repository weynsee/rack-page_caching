require "bundler/gem_tasks"
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.pattern = "test/**/*_spec.rb"
  t.libs << 'test'
end

task :default => :test
