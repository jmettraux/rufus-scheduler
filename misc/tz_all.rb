
require 'tzinfo'
# if tzinfo-data is installed, tzinfo picks it up
# automatically

#TZInfo::Timezone.all.each { |tz| puts tz.name }

tzs = TZInfo::Timezone.all.sort_by { |tz| tz.name.length }
puts "TIMEZONES = %["
l = 0
tzs.each do |tz|
  if l + tz.name.length > 79
    puts; l = 0
  elsif l > 0
    print ' '; l += 1
  end
  l += tz.name.length
  print tz.name;
end
puts "\n]"

