
= rufus-scheduler

rufus-scheduler is a Ruby gem for scheduling pieces of code (jobs). It understands running a job AT a certain time, IN a certain time, EVERY x time or simply via a CRON statement.

rufus-scheduler is no replacement for cron/at since it runs inside of Ruby.


== alternatives / complements

A list of related Ruby projects :

http://github.com/javan/whenever
http://github.com/yakischloba/em-timers/

More like complements :

http://github.com/mojombo/chronic/
http://github.com/hpoydar/chronic_duration


== installation

  sudo gem install rufus-scheduler


== usage

The usage is similar to the one of the old rufus-scheduler. There are a few differences though.

  require 'rubygems'
  require 'rufus/scheduler'

  scheduler = Rufus::Scheduler.start_new

  scheduler.in '20m' do
    puts "order ristretto"
  end

  scheduler.at 'Thu Mar 26 07:31:43 +0900 2009' do
    puts 'order pizza'
  end

  scheduler.cron '0 22 * * 1-5' do
    # every day of the week at 00:22
    puts 'enable security system'
  end

  scheduler.every '5m' do
    puts 'check blood pressure'
  end

  # ...

  scheduler.stop


This code summons a plain version of the scheduler, this can be made more explicit via :

  scheduler = Rufus::Scheduler::PlainScheduler.start_new



== the time strings understood by rufus-scheduler

  require 'rubygems'
  require 'rufus/scheduler'

  p Rufus.parse_time_string '500'      # => 0.5
  p Rufus.parse_time_string '1000'     # => 1.0
  p Rufus.parse_time_string '1h'       # => 3600.0
  p Rufus.parse_time_string '1h10s'    # => 3610.0
  p Rufus.parse_time_string '1w2d'     # => 777600.0

  p Rufus.to_time_string 60              # => "1m"
  p Rufus.to_time_string 3661            # => "1h1m1s"
  p Rufus.to_time_string 7 * 24 * 3600   # => "1w"


== looking up jobs

== tags

You can specify tags at schedule time :

  scheduler.in '2d', :tags => 'admin' do
    run_backlog_cleaning()
  end
  scheduler.every '3m', :tags => 'production' do
    check_order_log()
  end

And later query the scheduler for those jobs :

  admin_jobs = scheduler.find_by_tag('admin')
  production_jobs = scheduler.find_by_tag('production')


== unscheduling jobs

== exceptions in jobs

== frequency

The default frequency for the scheduler is 0.330 seconds. This means that the usual scheduler implementation will wake up, trigger jobs that are to be triggered and then go back to sleep for 0.330 seconds. Note that this doesn't mean that the scheduler will wake up very 0.330 seconds (checking and triggering do take time).

You can set a different frequency when starting / initializing the scheduler :

  require 'rubygems'
  require 'rufus/scheduler'

  scheduler = Rufus::Scheduler.start_new(:frequency => 60.0)
    # for a lazy scheduler that only wakes up every 60 seconds


== usage with EventMachine

rufus-scheduler 2.0 can be used in conjunction with EventMachine (http://github.com/eventmachine/eventmachine/).

More and more ruby applications are using EventMachine. This flavour of the scheduler relies on EventMachine, thus it doesn't require a separate thread like the PlainScheduler does.

  require 'rubygems'
  require 'eventmachine'

  EM.run {

    scheduler = Rufus::Scheduler::EmScheduler.start_new

    scheduler.in '20m' do
      puts "order ristretto"
    end
  }


== tested with

ruby 1.8.6, ruby 1.9.1p0
on jruby 1.2.0 it has some tiny issues (spec/blocking_spec.rb)


== dependencies

the ruby gem 'eventmachine' if you use Rufus::Scheduler::EmScheduler, else no other dependencies.


== mailing list

On the rufus-ruby list :

http://groups.google.com/group/rufus-ruby


== issue tracker

http://rubyforge.org/tracker/?atid=18584&group_id=4812&func=browse


== irc

  irc.freenode.net #ruote


== source

http://github.com/jmettraux/rufus-scheduler

  git clone git://github.com/jmettraux/rufus-scheduler.git


== credits

http://github.com/jmettraux/rufus-scheduler/blob/master/CREDITS.txt


== authors

John Mettraux, jmettraux@gmail.com, http://jmettraux.wordpress.com


== the rest of Rufus

http://rufus.rubyforge.org


== license

MIT

