RSpec.describe DeckType do
  def deck(text)
    parse_deck("// NAME: X\n" + text)
  end

  def deck_type(sections)
    DeckType.new(name: "Test Type", category: "deck", format: nil, sections: sections)
  end

  describe "#validate" do
    it "accepts exact integer sizes" do
      type = deck_type("Main Deck" => 60, "Sideboard" => 15)
      expect { expect(type.validate(deck("60 Forest\nSideboard\n15 Island\n"))).to be true }.not_to output.to_stderr
    end

    it "rejects wrong integer sizes" do
      type = deck_type("Main Deck" => 60)
      expect {
        expect(type.validate(deck("59 Forest\n"))).to be false
      }.to output(/of type Test Type section Main Deck has invalid size 59, should be 60/).to_stderr
    end

    it "accepts any size listed in an array" do
      type = deck_type("Main Deck" => 60, "Sideboard" => [0, 1])
      expect(type.validate(deck("60 Forest\n"))).to be true
      expect(type.validate(deck("60 Forest\nSideboard\n1 Island\n"))).to be true
      expect {
        expect(type.validate(deck("60 Forest\nSideboard\n2 Island\n"))).to be false
      }.to output(/section Sideboard has invalid size 2, should be \[0, 1\]/).to_stderr
    end

    it "treats a missing section as size 0" do
      type = deck_type("Main Deck" => 60, "Sideboard" => 15)
      expect {
        expect(type.validate(deck("60 Forest\n"))).to be false
      }.to output(/section Sideboard has invalid size 0/).to_stderr
    end

    it "accepts any size for sections marked any" do
      type = deck_type("Main Deck" => "any")
      expect(type.validate(deck("1 Forest\n"))).to be true
      expect(type.validate(deck("1000 Forest\n"))).to be true
    end

    it "rejects unexpected sections" do
      type = deck_type("Main Deck" => "any")
      expect {
        expect(type.validate(deck("1 Forest\nSideboard\n1 Island\n"))).to be false
      }.to output(/of type Test Type has unexpected section Sideboard/).to_stderr
    end

    it "allows unexpected sections containing only tokens" do
      type = deck_type("Main Deck" => "any")
      expect(type.validate(deck("1 Forest\nSideboard\n1 Soldier [token]\n"))).to be true
    end

    it "does not count tokens towards section size" do
      type = deck_type("Main Deck" => 60)
      expect(type.validate(deck("60 Forest\n5 Soldier [token]\n"))).to be true
    end

    it "validates Main Deck + Commander as a combined size" do
      type = deck_type("Main Deck" => [98, 99], "Commander" => [1, 2], "Main Deck + Commander" => 100)
      expect(type.validate(deck("COMMANDER: 1 Atraxa, Praetors' Voice\n99 Forest\n"))).to be true
      expect(type.validate(deck("COMMANDER: 1 Tymna the Weaver\nCOMMANDER: 1 Thrasios, Triton Hero\n98 Forest\n"))).to be true
      expect {
        expect(type.validate(deck("COMMANDER: 1 Atraxa, Praetors' Voice\n100 Forest\n"))).to be false
      }.to output(/section Main Deck \+ Commander has invalid size 101, should be 100/).to_stderr
    end

    it "reports every problem, not just the first" do
      type = deck_type("Main Deck" => 60, "Sideboard" => 15)
      expect {
        expect(type.validate(deck("59 Forest\nSideboard\n14 Island\nPlanar Deck\n1 Akoum\n"))).to be false
      }.to output(/unexpected section Planar Deck.*Main Deck has invalid size 59.*Sideboard has invalid size 14/m).to_stderr
    end

    it "raises on malformed rules" do
      type = deck_type("Main Deck" => "sixty")
      expect { type.validate(deck("60 Forest\n")) }.to raise_error(/Section validation rule invalid: Test Type Main Deck "sixty"/)
    end
  end

  describe "loaded types" do
    it "looks up types by key" do
      type = DeckType["cmd"]
      expect(type).to be_a(DeckType)
      expect(type.name).to eq("Commander Deck")
      expect(type.category).to eq("deck")
      expect(type.format).to eq("commander")
    end

    it "returns nil for unknown types" do
      expect(DeckType["no-such-type"]).to be_nil
    end

    it "defaults sections to Main Deck of any size" do
      types = YAML.load_file("#{__dir__}/../lib/deck_types.yaml")
      name = types.keys.find{|k| !types[k].key?("sections") }
      skip "every type declares sections" unless name
      type = DeckType[name]
      expect(type.validate(deck("37 Forest\n"))).to be true
    end

    it "has well-formed rules for every type" do
      YAML.load_file("#{__dir__}/../lib/deck_types.yaml").each do |key, description|
        (description["sections"] || {}).each do |section, size|
          valid = size == "any" || size.is_a?(Integer) || (size.is_a?(Array) && size.all?(Integer))
          expect(valid).to be(true), "#{key} #{section}: #{size.inspect}"
        end
      end
    end
  end
end
