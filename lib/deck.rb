class Deck
  attr_reader :release_date, :source, :display

  def initialize(path)
    @cards = []
    @sideboard = []
    @commander = []
    @bonus = []

    lines = Pathname(path).readlines.map(&:chomp).grep(/\S/)
    main_lines = lines.grep_v(%r[^\s*/])
    meta_lines = lines.grep(%r[^\s*/])
    @release_date = meta_lines.map{|x| x[%r[^\s*//\s*DATE:\s*(.*)], 1] }.compact.first
    @release_date = nil if @release_date == "-"
    @source = meta_lines.map{|x| x[%r[^\s*//\s*SOURCE:\s*(.*)], 1] }.compact.first
    @display = meta_lines.map{|x| x[%r[^\s*//\s*DISPLAY:\s*(.*)], 1] }.compact.first

    section = @cards

    main_lines.each do |line|
      if line == "Sideboard" or line == "Planar Deck"
        section = @sideboard
        next
      end

      if line == "Bonus" or line == "Display Commander"
        section = @bonus
        next
      end

      target = section
      if line.sub!(/\ACOMMANDER:\s+/, "")
        target = @commander
      end

      count, name = line.split(" ", 2)
      if name == nil
        raise("Failed card definition for #{line}")
      end
      name = name.sub(/\s*\*+\z/, "")
      foil = nil
      set = nil
      number = nil
      token = nil

      if name.sub!(/\[foil\]/i, "")
        foil = true
      end

      if name.sub!(/\[token\]/i, "")
        token = true
      end

      if name.sub!(/\[(.*?):(.*?)\]/, "")
        set = $1
        number = $2
      elsif name.sub!(/\[([^:]+?)\]/, "")
        set = $1
      end

      name.strip!

      if name.empty?
        raise("Cannot parse line: #{line}")
      end

      target << {
        name: name,
        count: count.to_i,
        set: set,
        number: number,
        foil: foil,
        token: token,
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

  def bonus_data
    @bonus
  end
end
