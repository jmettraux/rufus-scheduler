
Gem::Specification.new do |s|

  s.name = 'rufus-scheduler'

  s.version = File.read(
    File.expand_path('../lib/rufus/scheduler.rb', __FILE__)
  ).match(/ VERSION *= *['"]([^'"]+)/)[1]

  s.platform = Gem::Platform::RUBY
  s.authors = [ 'John Mettraux' ]
  s.email = [ 'jmettraux@gmail.com' ]
  s.homepage = 'http://github.com/jmettraux/rufus-scheduler'
  s.rubyforge_project = 'rufus'
  s.license = 'MIT'
  s.summary = 'job scheduler for Ruby (at, cron, in and every jobs)'

  s.description = %{
job scheduler for Ruby (at, cron, in and every jobs).
  }.strip

  #s.files = `git ls-files`.split("\n")
  s.files = Dir[
    'Rakefile',
    'lib/**/*.rb', 'spec/**/*.rb', 'test/**/*.rb',
    '*.gemspec', '*.txt', '*.rdoc', '*.md'
  ]

  #s.add_runtime_dependency 'tzinfo'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '>= 2.13.0'
  s.add_development_dependency 'chronic'
  s.add_development_dependency 'tzinfo'

  s.require_path = 'lib'
end

