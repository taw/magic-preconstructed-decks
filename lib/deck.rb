class Deck
  def initialize(path)
    @lines = Pathname(path).readlines.map(&:chomp).grep_v(%r[^\s*/]).grep(/\S/)
    raise unless @lines.pop == "Sideboard"
    @cards = @lines.map{|c| c.split(" ", 2)}.map{|c,n| [c.to_i, n]}
  end

  def size
    @cards.map(&:first).inject(0, &:+)
  end

  def sideboard_size
    0
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
    []
  end
end
