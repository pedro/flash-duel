describe "Flash Duel" do
  let(:p1) { FlashDuel::Bot.new }
  let(:p2) { FlashDuel::Bot.new }
  let(:game) { FlashDuel::Engine.new(p1, p2) }

  it "has a board" do
    game.board.should_not be_nil
  end

  it "puts the first player on the first position" do
    game.first_player = p2
    game.board.position(p2).should == 1
  end

  it "puts the other player on the last position" do
    game.first_player = p2
    game.board.position(p1).should == 18
  end

  it "has 25 cards on the deck" do
    game.deck.should have(25).cards
  end

  it "gives 5 cards to each player" do
    game.hands.each { |player, hand| hand.should have(5).cards }
    game.deck.should have(15).cards
  end

  context "gameplay" do
    before do
      game.first_player = p1
      game.hands = {
        p1 => [1, 2, 4, 5, 5],
        p2 => [1, 2, 4, 5, 5],
      }
    end

    it "passes the hand and board to the player" do
      p1.should_receive(:play).with([1, 2, 4, 5, 5], game.board).and_return [:move, 1]
      game.step
    end

    it "validates the action" do
      p1.should_receive(:play).and_return [:bad, 1]
      lambda { game.step }.should raise_error(FlashDuel::BadMove)
    end

    it "validates the qty" do
      p1.should_receive(:play).and_return [:move, 3]
      lambda { game.step }.should raise_error(FlashDuel::BadMove)
    end

    context "moving" do
      it "moves the player on the board" do
        p1.should_receive(:play).and_return [:move, 5]
        game.step
        game.board.pos[p1].should == 6
      end

      it "moves the player on the other side the opposite direction" do
        game.current = p2
        p2.should_receive(:play).and_return [:move, 5]
        game.step
        game.board.pos[p2].should == 13
      end

      it "adjust the player movement so he will stop next to the other player when moving a longer distance" do
        p1.should_receive(:play).and_return [:move, 5]
        game.board.pos[p2] = 4
        game.step
        game.board.pos[p1].should == 3
      end

      it "adjusts the movement for players on the other side" do
        game.current = p2
        p2.should_receive(:play).and_return [:move, 5]
        game.board.pos[p1] = 15
        game.step
        game.board.pos[p2].should == 16
      end

      it "gives a card back to the player" do
        p1.should_receive(:play).and_return [:move, 5]
        game.step
        game.hands[p1].should have(5).cards
      end

      it "doesn't allow discarding multiple cards" do
        p1.should_receive(:play).and_return [:move, [1, 2]]
        lambda { game.step }.should raise_error(FlashDuel::BadMove)
      end
    end

    context "pushing" do
      before do
        game.board.pos[p2] = 2
      end

      it "moves the other player on the board" do
        p1.should_receive(:play).and_return [:push, 5]
        game.step
        game.board.pos[p2].should == 7
      end

      it "gives a card back to the player" do
        p1.should_receive(:play).and_return [:push, 5]
        game.step
        game.hands[p1].should have(5).cards
      end

      it "doesn't allow it unless the players are next to each other" do
        game.board.pos[p2] = 18
        p1.should_receive(:play).and_return [:push, 5]
        lambda { game.step }.should raise_error(FlashDuel::BadMove)
      end

      it "doesn't allow discarding multiple cards" do
        p1.should_receive(:play).and_return [:push, [1, 2]]
        lambda { game.step }.should raise_error(FlashDuel::BadMove)
      end
    end

    context "attacking" do
      before do
        game.board.pos = { p1 => 1, p2 => 6 }
      end

      it "validates the distance" do
        p1.should_receive(:play).and_return [:attack, 1]
        lambda { game.step }.should raise_error(FlashDuel::BadMove)
      end

      context "responding" do
        before do
          p1.should_receive(:play).and_return [:attack, [5, 5]]
        end

        it "asks the other player to respond" do
          p2.should_receive(:respond).with(:attack, [5, 5], [1, 2, 4, 5, 5], game.board).and_return [:block, [5, 5]]
          game.step
        end

        it "doesn't allow retreat" do
          p2.should_receive(:respond).and_return [:retreat, 2]
          lambda { game.step }.should raise_error(FlashDuel::BadResponse)
        end

        it "doesn't allow blocking with a different number" do
          game.hands[p2] = [3, 3, 3, 3, 3]
          p2.should_receive(:respond).and_return [:block, [3, 3]]
          lambda { game.step }.should raise_error(FlashDuel::BadResponse)
        end

        it "doesn't allow blocking using less cards" do
          p2.should_receive(:respond).and_return [:block, 5]
          lambda { game.step }.should raise_error(FlashDuel::BadResponse)
        end
      end
    end

    context "dashing strike" do
      before do
        game.board.pos = { p1 => 6, p2 => 15 }
      end

      it "validates the distance" do
        p1.should_receive(:play).and_return [:strike, [1, 5, 5]]
        lambda { game.step }.should raise_error(FlashDuel::BadMove)
      end

      it "cannot dash with only one card" do
        p1.should_receive(:play).and_return [:strike, 1]
        lambda { game.step }.should raise_error(FlashDuel::BadMove)
      end

      it "cannot dash attacking with different cards" do
        p1.should_receive(:play).and_return [:strike, [1, 2, 4]]
        lambda { game.step }.should raise_error(FlashDuel::BadMove)
      end

      context "responding" do
        before do
          p1.should_receive(:play).and_return [:strike, [4, 5, 5]]
        end

        it "asks the other player to respond" do
          p2.should_receive(:respond).with(:strike, [5, 5], [1, 2, 4, 5, 5], game.board).and_return [:block, [5, 5]]
          game.step
        end

        it "moves the other player on retreat" do
          p2.should_receive(:respond).and_return [:retreat, 2]
          game.step
          game.board.pos[p2].should == 17
        end

        it "adjusts the movement on retreat when close to the beggining of the board" do
          p2.should_receive(:respond).and_return [:retreat, 5]
          game.step
          game.board.pos[p2].should == 18
        end

        it "doesn't allow retreating if already on the edge" do
          game.board.pos = { p1 => 9, p2 => 18 }
          p2.should_receive(:respond).and_return [:retreat, 1]
          lambda { game.step }.should raise_error(FlashDuel::BadResponse)
        end

        it "doesn't allow blocking with a different number" do
          game.hands[p2] = [3, 3, 3, 3, 3]
          p2.should_receive(:respond).and_return [:block, [3, 3]]
          lambda { game.step }.should raise_error(FlashDuel::BadResponse)
        end

        it "doesn't allow blocking using less cards" do
          p2.should_receive(:respond).and_return [:block, 5]
          lambda { game.step }.should raise_error(FlashDuel::BadResponse)
        end
      end
    end
  end
end
