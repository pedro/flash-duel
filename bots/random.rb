class RandomBot
  def play(hand, board)
    actions = available_actions(hand, board)
    puts "available actions for #{hand.inspect} on #{board.inspect} are: #{actions.inspect}"
    actions[rand(actions.size)]
  end

  def respond(action, attack, hand, board)
    responses = available_responses(action, attack, hand, board)
    puts "available responses for #{action} #{hand.inspect} on #{board.inspect} are: #{responses.inspect}"
    responses[rand(responses.size)]
  end

  def available_actions(hand, board)
    actions = []

    # can move with any card on hand
    if board.distance > 1
      actions += hand.map { |card| [:move, card] }
    end

    # can push with any card on hand
    if board.distance == 1
      actions += hand.map { |card| [:push, card] }
    end

    qtys = hand.inject(Hash.new(0)) { |h, card| h[card] += 1; h }
    qty  = qtys[board.distance]

    # check if we can attack
    if qty > 0
      actions += (1..qty).map do |multiplier|
        [:attack, [board.distance] * multiplier]
      end
    end

    # check if we can dash strike
    hand.each_with_index do |base, i|
      next if base >= board.distance
      hand.each_with_index do |attack, j|
        next if i == j
        qty = qtys[attack]
        qty -= 1 if base == attack
        if base + attack == board.distance
          actions += (1..qty).map do |multiplier|
            [:strike, [base] + [attack] * multiplier]
          end
        end
      end
    end

    actions.uniq
  end

  def available_responses(action, attack, hand, board)
    responses = []

    # check if we can block
    value = attack.first
    defense = hand.select { |c| c == value }

    if attack.size <= defense.size
      responses += [[:block, defense[0, attack.size]]]
    end

    # check if we can retreat
    if action == :strike && !board.on_edge?(self)
      responses += hand.map { |card| [:retreat, card] }
    end

    responses.uniq
  end
end