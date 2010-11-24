module FlashDuel
  class Board
    attr_accessor :p1, :p2, :pos, :discarded

    def initialize(p1, p2)
      @p1 = p1
      @p2 = p2

      @pos = { @p1 => 1, @p2 => 18 }
      @discarded = []
    end

    def position(player)
      pos[player]
    end

    def distance
      a, b = pos.values
      (a - b).abs
    end

    def furthest_player
      d1 = position(p1) -1
      d2 = 18 -position(p2)

      return p1 if d1 > d2
      return p2 if d2 > d1
      nil # same
    end

    def on_edge?(player)
      [1, 18].include? pos[player]
    end

    def move(player, qty, options={})
      raise "Invalid move from #{player.inspect}: not on the board" unless [p1, p2].include?(player)
      raise "Invalid move from #{player.inspect}: bad qty #{qty.inspect}" unless (1..5).to_a.include?(qty.abs)

      qty = qty * -1 if player == p2
      new_pos = pos[player] + qty
      raise "Invalid move from #{player.inspect}: position occupied" if pos.values.include?(new_pos)

      if options[:respect_limits]
        new_pos = 1 if new_pos < 1
        new_pos = 18 if new_pos > 18
      else
        raise "Invalid move from #{player.inspect}: going off the board" if new_pos < 1
        raise "Invalid move from #{player.inspect}: going off the board" if new_pos > 18
      end

      pos[player] = new_pos
    end

    def inspect
      pos.inspect
    end
  end
end