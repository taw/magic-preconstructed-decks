class Deck
  attr_reader :path, :release_date, :source, :display, :sections, :languages, :name

  def initialize(path)
    @path = path
    @sections = Hash.new{|ht,k| ht[k] = []}

    lines = Pathname(path).readlines.map(&:chomp).grep(/\S/)
    main_lines = lines.grep_v(%r[^\s*/])
    meta_lines = lines.grep(%r[^\s*/])
    @release_date = meta_lines.map{|x| x[%r[^\s*//\s*DATE:\s*(.*)], 1] }.compact.first
    @release_date = nil if @release_date == "-"
    @name = meta_lines.map{|x| x[%r[^\s*//\s*NAME:\s*(.*)], 1] }.compact.first
    @source = meta_lines.map{|x| x[%r[^\s*//\s*SOURCE:\s*(.*)], 1] }.compact.first
    @display = meta_lines.map{|x| x[%r[^\s*//\s*DISPLAY:\s*(.*)], 1] }.compact.join("\n")
    @languages = meta_lines.map{|x| x[%r[^\s*//\s*LANGUAGES?:\s*(.*)], 1] }.compact.first

    section_name = "Main Deck"

    main_lines.each do |line|
      case line.strip
      # All known sections
      when "Main Deck", "Sideboard", "Display Commander", "Commander", "Planar Deck", "Scheme Deck"
        section_name = line.strip
        next
      end

      target = section_name
      if line.sub!(/\ACOMMANDER:\s+/, "")
        target = "Commander"
      end

      count, card_name = line.split(" ", 2)
      if card_name == nil
        raise("Failed card definition for #{line}")
      end
      card_name = card_name.sub(/\s*\*+\z/, "")
      foil = nil
      set = nil
      number = nil
      token = nil
      etched = nil

      if card_name.sub!(/\[foil\]/i, "")
        foil = true
      end

      if card_name.sub!(/\[etched\]/i, "")
        etched = true
      end

      if card_name.sub!(/\[token\]/i, "")
        token = true
      end

      if card_name.sub!(/\[(.*?):(.*?)\]/, "")
        set = $1
        number = $2
      elsif card_name.sub!(/\[([^:]+?)\]/, "")
        set = $1
      end

      card_name.strip!

      if card_name.empty?
        raise("Cannot parse line: #{line}")
      end

      add_card(target,
        name: card_name,
        count: count.to_i,
        set: set,
        number: number,
        foil: foil,
        token: token,
        etched: etched,
      )
    end
  end

  def add_card(section_name, card)
    @sections[section_name] << card.compact
  end

  def section_sizes
    @sections.to_h{|k,v| [k, v.map{|c| c[:count]}.sum]}
  end
end
