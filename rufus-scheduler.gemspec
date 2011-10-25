
Gem::Specification.new do |s|

  s.name = 'rufus-scheduler'

  s.version = File.read(
    File.expand_path('../lib/rufus/sc/version.rb', __FILE__)
  ).match(/ VERSION *= *['"]([^'"]+)/)[1]

  s.platform = Gem::Platform::RUBY
  s.authors = [ 'John Mettraux' ]
  s.email = [ 'jmettraux@gmail.com' ]
  s.homepage = 'http://github.com/jmettraux/rufus-scheduler'
  s.rubyforge_project = 'rufus'
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

  s.add_runtime_dependency 'tzinfo', '>= 0.3.23'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '>= 2.7.0'

  s.require_path = 'lib'
end

