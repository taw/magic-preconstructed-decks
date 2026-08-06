class Deck
  attr_reader :path, :release_date, :source, :display, :sections, :languages, :name

  def initialize(path)
    @path = path
    @sections = Hash.new{|ht,k| ht[k] = []}

    lines = Pathname(path).readlines.map(&:chomp).grep(/\S/)
    main_lines = lines.grep_v(%r[^[ \t]*/])
    meta_lines = lines.grep(%r[^[ \t]*/])
    @release_date = meta_lines.map{|x| x[%r[^[ \t]*//[ \t]*DATE:[ \t]*(.*)], 1] }.compact.first
    @release_date = nil if @release_date == "-"
    @name = meta_lines.map{|x| x[%r[^[ \t]*//[ \t]*NAME:[ \t]*(.*)], 1] }.compact.first
    @source = meta_lines.map{|x| x[%r[^[ \t]*//[ \t]*SOURCE:[ \t]*(.*)], 1] }.compact.first
    display_lines = meta_lines.map{|x| x[%r[^[ \t]*//[ \t]*DISPLAY:[ \t]*(.*)], 1] }.compact
    @display = display_lines.empty? ? nil : display_lines.join("\n")
    @languages = meta_lines.map{|x| x[%r[^[ \t]*//[ \t]*LANGUAGES?:[ \t]*(.*)], 1] }.compact.first

    unless @name
      raise "#{path}: no deck name, add a `// NAME: ...` line"
    end

    section_name = "Main Deck"

    main_lines.each do |line|
      case line.strip
      # All known sections
      when "Main Deck", "Sideboard", "Display Commander", "Commander", "Planar Deck", "Scheme Deck"
        section_name = line.strip
        next
      end

      target = section_name
      # Work on a copy, so error messages can report the line as written in the file
      card_line = line.dup
      if card_line.sub!(/\ACOMMANDER:[ \t]+/, "")
        target = "Commander"
      end

      count, card_name = card_line.split(" ", 2)
      if card_name == nil
        raise("#{path}: no card name in line #{line.inspect}")
      end
      # Zero is rejected as well - merge_duplicates would silently drop such cards
      unless count =~ /\A[1-9]\d*\z/
        raise("#{path}: invalid card count #{count.inspect} in line #{line.inspect}")
      end
      card_name = card_name.sub(/[ \t]*\*+\z/, "")
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
        raise("#{path}: cannot parse line #{line.inspect}")
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
    @sections.to_h do |name, contents|
      [
        name,
        contents.reject{|c| c[:token]}.map{|c| c[:count]}.sum
      ]
    end
  end

  def merge_duplicates
    @sections.each do |section_name, section|
      map = {}
      section.each do |card|
        key = card.except(:count)
        if map[key]
          map[key][:count] += card[:count]
          card[:count] = 0
        else
          map[key] = card
        end
      end
      section.delete_if{|card| card[:count] == 0}
    end
  end
end
