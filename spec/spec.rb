
#
# specifying rufus-scheduler-em
#
# Fri Mar 20 22:54:46 JST 2009
#

specs = Dir["#{File.dirname(__FILE__)}/*_spec.rb"]

specs = specs - [ 'spec/stress_schedule_unschedule_spec.rb' ]
  # this spec takes 11 minutes, removing it from the regular spec run

specs.each { |path| load(path) }

