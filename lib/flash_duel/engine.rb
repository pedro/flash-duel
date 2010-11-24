module FlashDuel

  class PlayerException < Exception
    attr_accessor :player

    def initialize(player, message=nil)
      super "Wrong action from #{player}: #{message}"
    end
  end

  class BadMove < PlayerException; end
  class BadResponse < PlayerException; end

  class Engine

    def self.load_player(contents)
      m = Module.new
      m.class_eval(contents)
      m.const_get(m.constants.first).new
    end

    attr_accessor :p1, :p2, :board, :first_player, :current, :winner, :deck, :hands, :draw

    def initialize(p1, p2)
      @p1 = p1
      @p2 = p2
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
      step while !winner && !draw
    rescue PlayerError => e
      puts "#{e.player} FAILED: #{e.message}"
      self.winner = other_player(e.player)
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
        return time_over! if deck.empty?
        hand << deck.pop
      end

      self.current = other
    end

    def time_over!
      log "time-over!"
      log " -- #{can_attack?(p1)} / #{can_attack?(p2)}"
      if can_attack?(p1) && !can_attack?(p2)
        self.winner = p1
      elsif can_attack?(p2) && !can_attack?(p1)
        self.winner = p2
      elsif furthest = board.furthest_player
        self.winner = furthest
      else
        self.draw = true
      end
    end

    def can_attack?(player)
      hand     = hands[player]
      distance = board.distance
      return true if hand.any? { |c| c == distance }
      hand.each do |b|
        hand.each do |a|
          return true if a + b == distance
        end
      end
      return false
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

    def draw?
      draw
    end
  end
end
