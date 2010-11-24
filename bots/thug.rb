class Thug
  def play(hand, board)
    sorted = hand.sort.reverse
    qtys   = hand.inject(Hash.new(0)) { |h, card| h[card] += 1; h }
    qty    = qtys[board.distance]

    # attack if possible, using the biggest multiplier possible
    if qty > 0
      return [:attack, [board.distance] * qty]
    end

    # dash strike if possible
    hand.each_with_index do |base, i|
      next if base >= board.distance
      hand.each_with_index do |attack, j|
        next if i == j
        if base + attack == board.distance
          return [:strike, [base, attack]]
        end
      end
    end

    # push
    return [:push, sorted.first] if board.distance == 1

    # heck, I guess I need to move
    [:move, sorted.last]
  end

  def respond(action, attack, hand, board)
    sorted  = hand.sort.reverse
    value   = attack.first
    defense = hand.select { |c| c == value }

    # block if possible
    if attack.size <= defense.size
      return [:block, defense[0, attack.size]]
    end

    # guess I need to retreat
    if action == :strike && !board.on_edge?(self)
      return [:retreat, sorted.last]
    end
  end
end