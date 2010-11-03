
require 'rubygems'
require 'rake'


load 'lib/rufus/sc/version.rb'


#
# CLEAN

require 'rake/clean'
CLEAN.include('pkg', 'tmp', 'rdoc')


#
# TEST / SPEC

task :spec do
  sh 'rspec spec/'
end
task :test => :spec

task :default => :spec


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
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'jeweler'

  # gemspec spec : http://www.rubygems.org/read/chapter/20
end
Jeweler::GemcutterTasks.new


#
# DOC

#
# make sure to have rdoc 2.5.x to run that
#
require 'rake/rdoctask'
Rake::RDocTask.new do |rd|

  rd.main = 'README.rdoc'
  rd.rdoc_dir = 'rdoc/rufus-scheduler'
  rd.title = "rufus-scheduler #{Rufus::Scheduler::VERSION}"

  rd.rdoc_files.include(
    'README.rdoc', 'CHANGELOG.txt', 'LICENSE.txt', 'CREDITS.txt', 'lib/**/*.rb')
end


#
# TO THE WEB

task :upload_rdoc => [ :clean, :rdoc ] do

  account = 'jmettraux@rubyforge.org'
  webdir = '/var/www/gforge-projects/rufus'

  sh "rsync -azv -e ssh rdoc/rufus-scheduler #{account}:#{webdir}/"
end

