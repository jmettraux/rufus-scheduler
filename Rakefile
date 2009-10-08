
require 'rubygems'

require 'fileutils'
require 'rake'
require 'rake/clean'
require 'rake/packagetask'
require 'rake/gempackagetask'
require 'rake/testtask'


gemspec = File.read('rufus-scheduler.gemspec')
eval "gemspec = #{gemspec}"

#
# tasks

CLEAN.include('pkg', 'tmp', 'html')

task :default => [ :clean, :repackage ]


#
# SPECING

task :spec do
  load File.dirname(__FILE__) + '/spec/spec.rb'
end


#
# TESTING

task :test => :spec


#
# VERSION

task :change_version do

  version = ARGV.pop
  `sedip "s/VERSION = '.*'/VERSION = '#{version}'/" lib/rufus/sc/scheduler.rb`
  `sedip "s/s.version = '.*'/s.version = '#{version}'/" rufus-scheduler.gemspec`
  exit 0 # prevent rake from triggering other tasks
end


#
# PACKAGING

Rake::GemPackageTask.new(gemspec) do |pkg|
  #pkg.need_tar = true
end

Rake::PackageTask.new('rufus-scheduler', gemspec.version) do |pkg|

  pkg.need_zip = true
  pkg.package_files = FileList[
    'Rakefile',
    '*.txt',
    'lib/**/*',
    'spec/**/*',
    'test/**/*'
  ].to_a
  #pkg.package_files.delete("MISC.txt")
  class << pkg
    def package_name
      "#{@name}-#{@version}-src"
    end
  end
end


#
# DOCUMENTATION

task :rdoc do
  sh %{
    rm -fR html
    yardoc 'lib/**/*.rb' -o html/rufus-scheduler --title 'rufus-scheduler' --files CHANGELOG.txt,LICENSE.txt,CREDITS.txt
  }
end


#
# WEBSITE

task :upload_website => [ :clean, :rdoc ] do

  account = 'jmettraux@rubyforge.org'
  webdir = '/var/www/gforge-projects/rufus'

  sh "rsync -azv -e ssh html/rufus-scheduler #{account}:#{webdir}/"
end

