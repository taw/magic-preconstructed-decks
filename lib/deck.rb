class Deck
  attr_reader :release_date

  def initialize(path)
    @cards = []
    @sideboard = []
    @commander = []

    lines = Pathname(path).readlines.map(&:chomp).grep(/\S/)
    main_lines = lines.grep_v(%r[^\s*/])
    meta_lines = lines.grep(%r[^\s*/])
    @release_date = meta_lines.map{|x| x[%r[^\s*//\s*DATE:\s*(.*)], 1] }.compact.first
    @release_date = nil if @release_date == "-"

    in_sideboard = false

    main_lines.each do |line|
      if line == "Sideboard"
        in_sideboard = true
        next
      end

      if in_sideboard
        target = @sideboard
      else
        target = @cards
      end
      if line.sub!(/\ACOMMANDER:\s+/, "")
        target = @commander
      end

      count, name = line.split(" ", 2)
      name = name.sub(/\s*\*+\z/, "")
      foil = nil
      set = nil
      number = nil

      if name.sub!(/\[foil\]/, "")
        foil = true
      end

      if name.sub!(/\[(.*?):(.*?)\]/, "")
        set = $1
        number = $2
      elsif name.sub!(/\[([^:]+?)\]/, "")
        set = $1
      end

      name.strip!

      target << {
        name: name,
        count: count.to_i,
        set: set,
        number: number,
        foil: foil,
      }.compact
    end
  end

  def size
    @cards.map{|c| c[:count]}.sum
  end

  def sideboard_size
    @sideboard.map{|c| c[:count]}.sum
  end

  def commander_size
    @commander.map{|c| c[:count]}.sum
  end

  def card_data
    @cards
  end

  def sideboard_data
    @sideboard
  end

  def commander_data
    @commander
  end
end
