require "board"
require "engine"

module FlashDuel
  class Application < Sinatra::Base
    set :root, File.dirname(__FILE__)

    get "/" do
      erb :form
    end

    post "/game" do
      p1 = FlashDuel::Engine.load_player(params[:p1], "p1")
      p2 = FlashDuel::Engine.load_player(params[:p2], "p2")
      @game = FlashDuel::Engine.new(p1, p2)
      @game.run

      puts "here #{p1.inspect} #{p2.inspect} #{@game.winner.inspect}"
      if @game.winner == p1
        @winner = 'p1'
      else
        @winner = 'p2'
      end

      erb :form
    end
  end
end