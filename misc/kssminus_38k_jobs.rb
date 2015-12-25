
require 'rufus-scheduler'

p [ RUBY_VERSION, RUBY_PLATFORM ]

crons = [
  '* * * * *',
  '*/5 * * * *',
  '*/10 * * * *',
  '10 4 * * *',
  '35 */3 * * *',
  '* */3 * * *',
  '16 */4 * * *',
  '30 14 * * *',
  '26 */2 * * *'
]

total = 38_000 / crons.length

crons.each do |cron|
  s = Rufus::Scheduler.new
  t0 = Time.now
  total.times do
    s.cron(cron) {}
  end
  p [ cron, Time.now - t0 ]
  s.shutdown
end

