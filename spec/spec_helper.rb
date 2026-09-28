require "pathname"
require "tmpdir"
require_relative "../lib/deck"
require_relative "../lib/deck_types"

module DeckHelpers
  # Deck only reads from a path, so write the decklist to a temporary file
  def parse_deck(text)
    Dir.mktmpdir do |dir|
      path = Pathname(dir) + "deck.txt"
      path.write(text)
      Deck.new(path.to_s)
    end
  end
end

RSpec.configure do |config|
  config.include DeckHelpers
  config.disable_monkey_patching!
end
