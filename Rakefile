
require 'rake'
require 'rake/testtask'

desc 'Test gmaps_tools plugin'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_tests.rb']
  t.verbose = false
end
