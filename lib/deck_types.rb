require "yaml"

class DeckType
  attr_reader :name, :category, :format

  def initialize(name:, category:, format:, sections:)
    @name = name
    @category = category
    @format = format
    @sections = sections
  end

  def validate(deck)
    deck_sizes = deck.section_sizes
    deck_sizes.each do |section_name, section_size|
      # Allow extra sections if they're just tokens
      next if section_size == 0
      unless @sections[section_name]
        warn "#{deck.path} of type #{name} has unexpected section #{section_name}"
      end
    end
    @sections.each do |section_name, section_size|
      if section_name == "Main Deck + Commander"
        deck_section_size = deck_sizes.fetch("Main Deck", 0) + deck_sizes.fetch("Commander", 0)
      else
        deck_section_size = deck_sizes.fetch(section_name, 0)
      end

      case section_size
      when "any"
        next  # it's only used for allowed sections check
      when Integer
        next if section_size == deck_section_size
      when Array
        next if section_size.include?(deck_section_size)
      else
        raise "Section validation rule invalid: #{name} #{section_name} #{section_size.inspect}"
      end
      warn "#{deck.path} of type #{name} section #{section_name} has invalid size #{deck_section_size}, should be #{section_size.inspect}"
    end
  end

  def self.[](name)
    @types[name]
  end

  def self.load_data
    @types = {}
    YAML.load_file("#{__dir__}/deck_types.yaml").each do |name, description|
      description = description.map{|k,v| [k.to_sym, v]}.to_h
      description[:sections] ||= {"Main Deck" => "any"}
      @types[name] = DeckType.new(**description)
    end
  end
end

DeckType.load_data
