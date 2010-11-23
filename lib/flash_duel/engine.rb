module FlashDuel

  class PlayerError < RuntimeError
    def initialize(player, message)
      super "Wrong action from #{player}: #{message}"
    end
  end

  class BadMove < PlayerError; end
  class BadResponse < PlayerError; end

  class Engine

    def self.load_player(contents)
      m = Module.new
      m.class_eval(contents)
      m.const_get(m.constants.first).new
    end

    attr_accessor :p1, :p2, :board, :first_player, :current, :winner, :deck, :hands

    def initialize(p1, p2)
      @p1    = p1
      @p2    = p2
    end

    def board
      @board ||= Board.new(first_player, other_player(first_player))
    end

    def deck
      @deck ||= (1..5).map { |i| [i] * 5 }.flatten.sort_by { rand }
    end

    def hands
      @hands ||= {
        p1 => 5.times.to_a.map { deck.pop },
        p2 => 5.times.to_a.map { deck.pop },
      }
    end

    def run
      log "initializing match"
      step while !winner
    rescue Exception => e
      puts "#{current} FAILED: #{e.message}"
      self.winner = other_player(current)
    end

    def step
      self.current ||= first_player
      other = other_player(current)
      hand  = hands[current]
      log "turn for #{current}. hand is #{hand.inspect}"

      action, cards = request_move(current, hand, board)
      log "#{current} played with #{action} #{cards.inspect}"

      case action
        when :move
          raise BadMove.new(current, "cannot discard two cards while moving") if cards.size != 1
          distance = adjust_distance(cards.first)
          board.move(current, distance)
        when :push
          raise BadMove.new(current, "cannot discard two cards while pushing") if cards.size != 1
          raise BadMove.new(current, "cannot push, players are not next to each other") if board.distance > 1
          board.move(other, -cards.first)
        when :attack, :strike
          raise BadMove.new(current, "cannot strike with only one card") if action == :strike && cards.size == 1
          board.move(current, cards.shift) if action == :strike
          value = cards.first
          raise BadMove.new(current, "attacking with different cards") if cards.uniq.size > 1
          raise BadMove.new(current, "cannot attack with #{value}") if value != board.distance
          response, cards_response = request_response(other, action, cards, hands[other], board)
          log "#{other} responded with #{response} #{cards_response.inspect}"
          case response
            when :retreat
              raise BadResponse.new(other, "cannot retreat from attack") if action == :attack
              raise BadResponse.new(other, "cannot retreat, already on the edge") if board.on_edge?(other)
              board.move(other, -cards_response.first, :respect_limits => true)
            when :block
              value_response = cards_response.first
              raise BadResponse.new(current, "cannot block #{value} with #{value_response}") if value != value_response
              raise BadResponse.new(current, "must block with #{cards.size}") if cards.size != cards_response.size
          end
      end

      while hand.size < 5
        if deck.empty?
          raise "TIME-OVER!"
        else
          hand << deck.pop
        end
      end

      self.current = other
    end

    def players
      [p1, p2]
    end

    def first_player
      @first_player ||= players[rand(2)]
    end

    def other_player(p)
      (players - [p]).first
    end

    def request_move(player, hand, board)
      action, cards = player.play(hand, board)
      cards = [cards] unless cards.is_a?(Array)

      raise BadMove.new(player, "expected action, got #{action.inspect}") \
        unless [:move, :push, :attack, :strike].include? action

      raise BadMove.new(player, "doesn't have the cards #{cards.inspect}") \
        unless cards.all? { |i| hand.include?(i) }

      return action, move(player, cards)
    end

    def request_response(player, action, attacking_cards, hand, board)
      response, cards = player.respond(action, attacking_cards, hand, board)
      cards = [cards] unless cards.is_a?(Array)

      raise BadResponse.new(player, "expected response, got #{response.inspect}") \
        unless [:block, :retreat].include?(response)

      raise BadResponse.new(player, "doesn't have the cards #{cards.inspect}") \
        unless cards.all? { |i| hand.include?(i) }

      return response, move(player, cards)
    end

    # move cards from the player hand to the board
    def move(player, cards)
      cards.each do |card|
        board.discarded << hands[player].delete_at(hands[player].index(card))
      end
    end

    def adjust_distance(distance)
      adjusted_distance = board.distance - 1
      return distance if adjusted_distance >= distance
      adjusted_distance
    end

    def log(msg)
      return unless ENV.has_key?('DEBUG')
      puts msg
    end
  end
end
