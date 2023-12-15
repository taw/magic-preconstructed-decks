class Deck
  attr_reader :path, :release_date, :source, :display, :sections

  def initialize(path)
    @path = path
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
      # All known sections
      when "Main Deck", "Sideboard", "Display Commander", "Commander", "Planar Deck", "Scheme Deck"
        section_name = line
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
      etched = nil

      if name.sub!(/\[foil\]/i, "")
        foil = true
      end

      if name.sub!(/\[etched\]/i, "")
        etched = true
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
