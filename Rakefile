require 'bundler/gem_tasks'
require 'rake/testtask'

task :default => :test

desc 'Run the tests'
Rake::TestTask.new do |t|
  t.libs.push 'lib'
  t.libs.push 'test'
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
end

desc 'Open a Pry console with environment'
task :console do
  exec "pry -Ilib -rcharazard"
end
