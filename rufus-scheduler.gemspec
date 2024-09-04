
Gem::Specification.new do |s|

  s.name = 'rufus-scheduler'

  s.version = File.read(
    File.expand_path('../lib/rufus/scheduler.rb', __FILE__)
  ).match(/ VERSION *= *['"]([^'"]+)/)[1]

  s.platform = Gem::Platform::RUBY
  s.authors = [ 'John Mettraux' ]
  s.email = [ 'jmettraux@gmail.com' ]
  s.homepage = 'https://github.com/jmettraux/rufus-scheduler'
  s.license = 'MIT'
  s.summary = 'job scheduler for Ruby (at, cron, in and every jobs)'

  s.description = %{
Job scheduler for Ruby (at, cron, in and every jobs). Not a replacement for crond.
  }.strip

  s.metadata = {
    'changelog_uri' => s.homepage + '/blob/master/CHANGELOG.md',
    'bug_tracker_uri' => s.homepage + '/issues',
    'homepage_uri' =>  s.homepage,
    'source_code_uri' => s.homepage,
    #'wiki_uri' => s.homepage + '/flor/wiki',
    #'documentation_uri' => s.homepage + '/tree/master/doc',
    #'mailing_list_uri' => 'https://groups.google.com/forum/#!forum/floraison',
    'rubygems_mfa_required' => 'true',
  }

  #s.files = `git ls-files`.split("\n")
  s.files = Dir[
    '{README,CHANGELOG,CREDITS,LICENSE}.{md,txt}',
    'Makefile',
    'lib/**/*.rb', #'spec/**/*.rb', 'test/**/*.rb',
    "#{s.name}.gemspec",
  ]

  s.required_ruby_version = '>= 1.9'

  s.add_runtime_dependency 'fugit', '~> 1.1', '>= 1.11.1'

  s.add_development_dependency 'rspec', '~> 3.7'
  s.add_development_dependency 'chronic', '~> 0.10'

  s.require_path = 'lib'
end

