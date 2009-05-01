
= rufus-scheduler

== alternatives

I recommend you have a look at Jake Douglas' em-timers, it's a set of helper methods for timers in EventMachine. It's simpler than rufus-scheduler-em and has a better Ruby feel.

http://github.com/yakischloba/em-timers/


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

  # ...

  scheduler.stop


== tested with

ruby 1.8.6, ruby 1.9.1p0
on jruby 1.2.0 it has some tiny issues (spec/blocking_spec.rb)


== dependencies

the ruby gem 'eventmachine'


== mailing list

On the rufus-ruby list :

http://groups.google.com/group/rufus-ruby


== issue tracker

http://rubyforge.org/tracker/?atid=18584&group_id=4812&func=browse


== irc

irc.freenode.net #ruote


== source

http://github.com/jmettraux/rufus-scheduler-em

  git clone git://github.com/jmettraux/rufus-scheduler-em.git


== credits

many thanks to the authors of eventmachine

http://rubyeventmachine.com


== authors

John Mettraux, jmettraux@gmail.com, http://jmettraux.wordpress.com


== the rest of Rufus

http://rufus.rubyforge.org


== license

MIT

