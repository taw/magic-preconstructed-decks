class Deck
  attr_reader :release_date, :source, :display, :sections

  def initialize(path)
    @sections = Hash.new{|ht,k| ht[k] = []}

    lines = Pathname(path).readlines.map(&:chomp).grep(/\S/)
    main_lines = lines.grep_v(%r[^\s*/])
    meta_lines = lines.grep(%r[^\s*/])
    @release_date = meta_lines.map{|x| x[%r[^\s*//\s*DATE:\s*(.*)], 1] }.compact.first
    @release_date = nil if @release_date == "-"
    @source = meta_lines.map{|x| x[%r[^\s*//\s*SOURCE:\s*(.*)], 1] }.compact.first
    @display = meta_lines.map{|x| x[%r[^\s*//\s*DISPLAY:\s*(.*)], 1] }.compact.first

    section_name = "Main Deck"

    main_lines.each do |line|
      case line
      when "Main Deck"
        section_name = "Main Deck"
        next
      when "Sideboard", "Planar Deck"
        section_name = "Sideboard"
        next
      when "Bonus", "Display Commander"
        section_name = "Bonus"
        next
      when "Commander"
        section_name = "Commander"
        next
      end

      target = section_name
      if line.sub!(/\ACOMMANDER:\s+/, "")
        target = "Commander"
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

      add_card(target,
        name: name,
        count: count.to_i,
        set: set,
        number: number,
        foil: foil,
        token: token,
      )
    end
  end

  def add_card(section_name, card)
    @sections[section_name] << card.compact
  end

  def size
    @sections["Main Deck"].map{|c| c[:count]}.sum
  end

  def sideboard_size
    @sections["Sideboard"].map{|c| c[:count]}.sum
  end

  def commander_size
    @sections["Commander"].map{|c| c[:count]}.sum
  end

  def card_data
    @sections["Main Deck"]
  end

  def sideboard_data
    @sections["Sideboard"]
  end

  def commander_data
    @sections["Commander"]
  end

  def bonus_data
    @sections["Bonus"]
  end
end
