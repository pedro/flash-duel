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

    # check if we can attack
    hand.each do |card|
      actions += [[:attack, card]] if board.distance == card
    end

    actions
  end

  def available_responses(action, attack, hand, board)
    responses = []

    # check if we can block
    value = attack.first
    defense = hand.select { |c| c == value }

    if attack.size == defense.size
      responses += [[:block, defense[0, attack.size]]]
    end

    # check if we can retreat
    if action == :strike && !board.on_edge?(self)
      responses += hand.map { |card| [:retreat, card] }
    end

    responses
  end
end