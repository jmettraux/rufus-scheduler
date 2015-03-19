
require 'tzinfo'
# if tzinfo-data is installed, tzinfo picks it up
# automatically

TZInfo::Timezone.all.each { |tz| puts tz.name }

