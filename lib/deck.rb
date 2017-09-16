class Deck
  def initialize(path)
    @cards = []
    @sideboard = []
    lines = Pathname(path).readlines.map(&:chomp).grep_v(%r[^\s*/]).grep(/\S/)
    target = @cards
    lines.each do |line|
      if line == "Sideboard"
        target = @sideboard
        next
      end
      count, name = line.split(" ", 2)
      target << [count.to_i, name.sub(/\*\z/, "")]
    end
  end

  def size
    @cards.map(&:first).inject(0, &:+)
  end

  def sideboard_size
    @sideboard.map(&:first).inject(0, &:+)
  end

  def card_data
    @cards.map{|c,n|
      {
        name: n,
        count: c,
      }
    }
  end

  def sideboard_data
    @sideboard.map{|c,n|
      {
        name: n,
        count: c,
      }
    }
  end
end
