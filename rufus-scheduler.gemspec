
$gemspec = Gem::Specification.new do |s|

  s.name = 'rufus-scheduler'
  s.version = '1.0.13'
  s.authors = [ 'John Mettraux' ]
  s.email = 'jmettraux@gmail.com'
  s.homepage = 'http://openwferu.rubyforge.org/scheduler.html'
  s.platform = Gem::Platform::RUBY
  s.summary = "scheduler for Ruby (at, cron and every jobs), formerly known as 'openwferu-scheduler'"

  s.require_path = 'lib'
  s.test_file = 'test/test.rb'
  s.has_rdoc = true
  s.extra_rdoc_files = [ 'README.txt', 'CHANGELOG.txt', 'CREDITS.txt' ]
  s.rubyforge_project = 'rufus'

  s.files = Dir['lib/**/*.rb'] + Dir['*.txt']
end

