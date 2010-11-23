$: << File.dirname(__FILE__) + "/lib/flash_duel"
require "sinatra"
require "web/application"
run FlashDuel::Application