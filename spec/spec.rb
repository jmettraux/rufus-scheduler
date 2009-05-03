
#
# specifying rufus-scheduler
#
# Fri Mar 20 22:54:46 JST 2009
#

specs = Dir["#{File.dirname(__FILE__)}/*_spec.rb"]

#specs = specs - [ 'spec/stress_schedule_unschedule_spec.rb' ]
  # this spec was a bit longish (11m) now it's OK (66.78s)

specs.each { |path| load(path) }

