
require 'rubygems'

require 'rake'
require 'rake/clean'
require 'rake/packagetask'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'


RUFUS_SCHEDULER_VERSION = "1.0.8"

#
# GEM SPEC

spec = Gem::Specification.new do |s|

    s.name              = "rufus-scheduler"
    s.version           = RUFUS_SCHEDULER_VERSION
    s.authors           = [ "John Mettraux" ]
    s.email             = "jmettraux@gmail.com"
    s.homepage          = "http://openwferu.rubyforge.org/scheduler.html"
    s.platform          = Gem::Platform::RUBY
    s.summary           = "scheduler for Ruby (at, cron and every jobs), formerly known as 'openwferu-scheduler'"
    #s.license           = "MIT"

    s.require_path      = "lib"
    #s.autorequire       = "rufus-scheduler"
    s.test_file         = "test/test.rb"
    s.has_rdoc          = true
    s.extra_rdoc_files  = [ 'README.txt', 'CHANGELOG.txt', 'CREDITS.txt' ]

    #[ 'rufus-lru' ].each do |d|
    #    s.requirements << d
    #    s.add_dependency d
    #end

    files = FileList[ "{bin,docs,lib,test}/**/*" ]
    files.exclude "rdoc"
    files.exclude "extras"
    s.files = files.to_a
end

#
# tasks

CLEAN.include("pkg", "html", "rdoc")

task :default => [ :clean, :repackage ]


#
# TESTING

Rake::TestTask.new(:test) do |t|

    t.libs << "test"
    t.test_files = FileList['test/test.rb']
    t.verbose = true
end

#
# PACKAGING

Rake::GemPackageTask.new(spec) do |pkg|
    #pkg.need_tar = true
end

Rake::PackageTask.new("rufus-scheduler", RUFUS_SCHEDULER_VERSION) do |pkg|

    pkg.need_zip = true
    pkg.package_files = FileList[
        "Rakefile",
        "*.txt",
        "lib/**/*",
        "test/**/*"
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

#ALLISON=`allison --path`
ALLISON="/Library/Ruby/Gems/1.8/gems/allison-2.0.3/lib/allison.rb"

Rake::RDocTask.new do |rd|

    rd.main = "README.txt"

    rd.rdoc_dir = "html/rufus-scheduler"

    rd.rdoc_files.include(
        "README.txt", "CHANGELOG.txt", "LICENSE.txt", "CREDITS.txt",
        "lib/**/*.rb")

    rd.title = "rufus-scheduler rdoc"

    rd.options << '-N' # line numbers
    rd.options << '-S' # inline source

    rd.template = ALLISON if File.exist?(ALLISON)
end


#
# WEBSITE

task :upload_website => [ :clean, :rdoc ] do

    account = "jmettraux@rubyforge.org"
    webdir = "/var/www/gforge-projects/rufus"

    sh "rsync -azv -e ssh html/rufus-scheduler #{account}:#{webdir}/"
end

