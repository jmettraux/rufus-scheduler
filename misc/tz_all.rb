
require 'tzinfo'
# if tzinfo-data is installed, tzinfo picks it up
# automatically

TZInfo::Timezone.all.each { |tz| puts tz.name }

#tzs = TZInfo::Timezone.all.sort_by { |tz| tz.name.length }
#print "TIMEZONES = %[\n  "
#tzs.each { |tz| print tz.name; print ' ' }
#puts "\n]"

