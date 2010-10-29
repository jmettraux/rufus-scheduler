
require 'rubygems'
require 'rake'


load 'lib/rufus/sc/version.rb'


#
# CLEAN

require 'rake/clean'
CLEAN.include('pkg', 'tmp', 'html')
task :default => [ :clean ]


#
# GEM

require 'jeweler'

Jeweler::Tasks.new do |gem|

  gem.version = Rufus::Scheduler::VERSION
  gem.name = 'rufus-scheduler'
  gem.summary = 'job scheduler for Ruby (at, cron, in and every jobs)'

  gem.description = %{
    job scheduler for Ruby (at, cron, in and every jobs).

    By default uses a Ruby thread, if EventMachine is present, it will rely on it.
  }
  gem.email = 'jmettraux@gmail.com'
  gem.homepage = 'http://github.com/jmettraux/rufus-scheduler/'
  gem.authors = [ 'John Mettraux' ]
  gem.rubyforge_project = 'rufus'

  gem.test_file = 'spec/spec.rb'

  #gem.add_dependency 'yajl-ruby'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'yard'
  gem.add_development_dependency 'bacon'
  gem.add_development_dependency 'jeweler'
  gem.add_development_dependency 'tzinfo'
  gem.add_development_dependency 'activesupport'

  # gemspec spec : http://www.rubygems.org/read/chapter/20
end
Jeweler::GemcutterTasks.new


#
# DOC

begin

  require 'yard'

  YARD::Rake::YardocTask.new do |doc|
    doc.options = [
      '-o', 'html/rufus-scheduler', '--title',
      "rufus-scheduler #{Rufus::Scheduler::VERSION}"
    ]
  end

rescue LoadError

  task :yard do
    abort "YARD is not available : sudo gem install yard"
  end
end


#
# TO THE WEB

task :upload_website => [ :clean, :yard ] do

  account = 'jmettraux@rubyforge.org'
  webdir = '/var/www/gforge-projects/rufus'

  sh "rsync -azv -e ssh html/rufus-scheduler #{account}:#{webdir}/"
end

