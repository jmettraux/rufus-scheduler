module Rufus
  module Lock
    # A lock that can always be acquired
    class Null
      def lock; true; end
      def locked?; true; end
      def unlock; true; end
    end
  end
end
