require 'tzinfo'
require 'whedon'

class Rufus::CronLine < Whedon::Schedule
  def initialize(line)
    self.raise_error_on_duplicate = true
    super(line)
  end
end
