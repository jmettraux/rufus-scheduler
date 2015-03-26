
require 'benchmark'

$:.unshift('lib')
require 'rufus/scheduler'

N = 10

puts
puts "Ruby: #{RUBY_PLATFORM} #{RUBY_VERSION}"
puts "N is #{N}"
puts

Benchmark.benchmark(Benchmark::Tms::CAPTION, 31) do |b|

  cl = Rufus::Scheduler::CronLine.new('*/2 * * * *')

  b.report('.next_time') do
    N.times { cl.next_time }
  end
  b.report('.frequency') do
    N.times { cl.frequency }
  end
end
