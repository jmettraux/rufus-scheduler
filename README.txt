
= rufus-scheduler

This gem was formerly known as 'openwferu-scheduler'. It has been repackaged as 'rufus-scheduler'. Old 'require' paths have been kept for backward compatibility (no need to update your code).

The new license is MIT (not much of a change, the previous license was BSD).


== getting it

    sudo gem install rufus-scheduler

or at

http://rubyforge.org/frs/?group_id=4812


== usage

some examples :

    require 'rubygems'
    require 'rufus/scheduler'

    scheduler = Rufus::Scheduler.start_new

    scheduler.in("3d") do
      regenerate_monthly_report()
    end
      #
      # will call the regenerate_monthly_report method
      # in 3 days from now

     scheduler.every "10m10s" do
       check_score(favourite_team) # every 10 minutes and 10 seconds
     end

     scheduler.cron "0 22 * * 1-5" do
       log.info "activating security system..."
       activate_security_system()
     end

     job_id = scheduler.at "Sun Oct 07 14:24:01 +0900 2009" do
       init_self_destruction_sequence()
     end

     scheduler.join # join the scheduler (prevents exiting)


For all the scheduling related information, see the Rufus::Scheduler class rdoc itself (http://rufus.rubyforge.org/rufus-scheduler/classes/Rufus/Scheduler.html) or the original OpenWFEru scheduler documentation at http://openwferu.rubyforge.org/scheduler.html

Apart from scheduling, There are also two interesting methods in this gem, they are named parse_time_string and to_time_string :

    require 'rubygems'
    require 'rufus/otime' # gem 'rufus_scheduler'

    Rufus.parse_time_string "500"        # => 0.5
    Rufus.parse_time_string "1000"       # => 1.0
    Rufus.parse_time_string "1h"         # => 3600.0
    Rufus.parse_time_string "1h10s"      # => 3610.0
    Rufus.parse_time_string "1w2d"       # => 777600.0

    Rufus.to_time_string 60                   # => '1m'
    Rufus.to_time_string 3661                 # => '1h1m1s'
    Rufus.to_time_string 7 * 24 * 3600        # => '1w'


Something about the rufus-scheduler, threads and ActiveRecord connections :

http://jmettraux.wordpress.com/2008/09/14/the-scheduler-and-the-active_record/


== dependencies

None.


== mailing list

On the rufus-ruby list[http://groups.google.com/group/rufus-ruby] :

    http://groups.google.com/group/rufus-ruby


== issue tracker

http://rubyforge.org/tracker/?atid=18584&group_id=4812&func=browse


== irc

irc.freenode.net #ruote


== source

http://github.com/jmettraux/rufus-scheduler

    git clone git://github.com/jmettraux/rufus-scheduler.git


== author

John Mettraux, jmettraux@gmail.com
http://jmettraux.wordpress.com


== the rest of Rufus

http://rufus.rubyforge.org


== license

MIT

