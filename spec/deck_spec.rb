RSpec.describe Deck do
  it "preserves full-art wildcard selection separately from regular lands" do
    deck = parse_deck("// NAME: X\n2 Plains [BFZ:*] [fullart]\n1 Plains [BFZ:*]\n")
    expect(deck.sections["Main Deck"]).to eq([
      {name: "Plains", count: 2, set: "BFZ", number: "*", fullart: true},
      {name: "Plains", count: 1, set: "BFZ", number: "*"},
    ])
  end

  describe "metadata" do
    it "parses all metadata lines" do
      deck = parse_deck(<<~DECK)
        // NAME: Test Deck
        // DATE: 2020-01-02
        // SOURCE: https://example.com/deck
        // DISPLAY: Some Card
        // DISPLAY: Other Card
        // LANGUAGES: en, de
        1 Forest
      DECK
      expect(deck.name).to eq("Test Deck")
      expect(deck.release_date).to eq("2020-01-02")
      expect(deck.source).to eq("https://example.com/deck")
      expect(deck.display).to eq("Some Card\nOther Card")
      expect(deck.languages).to eq("en, de")
    end

    it "accepts LANGUAGE as well as LANGUAGES" do
      deck = parse_deck("// NAME: X\n// LANGUAGE: ja\n1 Forest\n")
      expect(deck.languages).to eq("ja")
    end

    it "tolerates leading whitespace and tabs in metadata lines" do
      deck = parse_deck("  \t//\tNAME:\tTabbed\n1 Forest\n")
      expect(deck.name).to eq("Tabbed")
    end

    it "uses the first value if a field is repeated" do
      deck = parse_deck("// NAME: First\n// NAME: Second\n1 Forest\n")
      expect(deck.name).to eq("First")
    end

    it "defaults optional fields to nil" do
      deck = parse_deck("// NAME: X\n1 Forest\n")
      expect(deck.release_date).to be_nil
      expect(deck.source).to be_nil
      expect(deck.display).to be_nil
      expect(deck.languages).to be_nil
    end

    it "treats DATE: - as unknown date" do
      deck = parse_deck("// NAME: X\n// DATE: -\n1 Forest\n")
      expect(deck.release_date).to be_nil
    end

    it "ignores other comment lines" do
      deck = parse_deck("// NAME: X\n// just a note\n1 Forest\n")
      expect(deck.sections).to eq("Main Deck" => [{name: "Forest", count: 1}])
    end

    it "requires a name" do
      expect { parse_deck("1 Forest\n") }.to raise_error(/no deck name/)
    end

    it "keeps the path" do
      deck = parse_deck("// NAME: X\n1 Forest\n")
      expect(deck.path).to end_with("deck.txt")
    end
  end

  describe "cards" do
    def cards(text)
      parse_deck("// NAME: X\n" + text).sections["Main Deck"]
    end

    it "parses count and name" do
      expect(cards("4 Lightning Bolt\n12 Mountain\n")).to eq([
        {name: "Lightning Bolt", count: 4},
        {name: "Mountain", count: 12},
      ])
    end

    it "ignores blank lines" do
      expect(cards("\n1 Forest\n   \n\t\n1 Island\n")).to eq([
        {name: "Forest", count: 1},
        {name: "Island", count: 1},
      ])
    end

    it "parses set code" do
      expect(cards("1 Forest [m20]\n")).to eq([{name: "Forest", count: 1, set: "m20"}])
    end

    it "parses set code and collector number" do
      expect(cards("1 Forest [m20:277]\n")).to eq([{name: "Forest", count: 1, set: "m20", number: "277"}])
    end

    it "parses foil, etched, and token markers case-insensitively" do
      expect(cards("1 Sol Ring [cmr:472] [FOIL]\n")).to eq([{name: "Sol Ring", count: 1, set: "cmr", number: "472", foil: true}])
      expect(cards("1 Sol Ring [Etched] [cmr:472]\n")).to eq([{name: "Sol Ring", count: 1, set: "cmr", number: "472", etched: true}])
      expect(cards("1 Soldier [token] [m20]\n")).to eq([{name: "Soldier", count: 1, set: "m20", token: true}])
    end

    it "does not treat foil/etched/token markers as set codes" do
      expect(cards("1 Forest [foil]\n")).to eq([{name: "Forest", count: 1, foil: true}])
    end

    it "strips trailing asterisks" do
      expect(cards("1 Forest *\n1 Island**\n")).to eq([
        {name: "Forest", count: 1},
        {name: "Island", count: 1},
      ])
    end

    it "keeps split and double-faced card names intact" do
      expect(cards("1 Fire // Ice\n1 Delver of Secrets // Insectile Aberration [isd:51]\n")).to eq([
        {name: "Fire // Ice", count: 1},
        {name: "Delver of Secrets // Insectile Aberration", count: 1, set: "isd", number: "51"},
      ])
    end

    it "rejects lines without a card name" do
      expect { cards("4\n") }.to raise_error(/no card name in line "4"/)
    end

    it "rejects invalid counts" do
      expect { cards("Forest\n") }.to raise_error(/no card name/)
      expect { cards("x4 Forest\n") }.to raise_error(/invalid card count "x4"/)
      expect { cards("0 Forest\n") }.to raise_error(/invalid card count "0"/)
      expect { cards("-1 Forest\n") }.to raise_error(/invalid card count "-1"/)
      expect { cards("04 Forest\n") }.to raise_error(/invalid card count "04"/)
    end

    it "rejects lines that are only annotations" do
      expect { cards("1 [m20:277]\n") }.to raise_error(/cannot parse line "1 \[m20:277\]"/)
    end

    describe "double-sided tokens" do
      it "joins two printings like the card name" do
        expect(cards("2 Human Soldier [tiko:3] // Zombie [tc20:9] [token]\n")).to eq([
          {name: "Human Soldier // Zombie", count: 2, set: "tiko // tc20", number: "3 // 9", token: true},
        ])
      end

      it "does not care where the printings are" do
        expect(cards("5 Human // Treasure [token] [tc20:4] [tc20:19] [foil]\n")).to eq([
          {name: "Human // Treasure", count: 5, set: "tc20 // tc20", number: "4 // 19", foil: true, token: true},
        ])
      end

      it "accepts printings without numbers" do
        expect(cards("1 Inkling [tstx] // Treasure [tsnc] [token]\n")).to eq([
          {name: "Inkling // Treasure", count: 1, set: "tstx // tsnc", token: true},
        ])
        expect(cards("1 Inkling [tstx:4] // Treasure [tsnc] [token]\n")).to eq([
          {name: "Inkling // Treasure", count: 1, set: "tstx // tsnc", number: "4 // ", token: true},
        ])
      end

      it "rejects two printings for non-tokens" do
        expect { cards("1 Fire [m20:1] // Ice [m20:2]\n") }.to raise_error(/two printings are only allowed for tokens/)
      end

      it "rejects two printings without a two-faced name" do
        expect { cards("1 Human [tc20:4] [tc20:19] [token]\n") }.to raise_error(/two printings require a two-faced name/)
      end

      it "rejects three or more printings" do
        expect { cards("1 Human [tc20:4] // Treasure [tc20:19] [tc20:20] [token]\n") }.to raise_error(/too many printings/)
      end
    end
  end

  describe "sections" do
    it "puts cards in Main Deck by default" do
      deck = parse_deck("// NAME: X\n1 Forest\n")
      expect(deck.sections.keys).to eq(["Main Deck"])
    end

    it "switches between all known sections" do
      deck = parse_deck(<<~DECK)
        // NAME: X
        Commander
        1 Atraxa, Praetors' Voice
        Main Deck
        1 Forest
        Sideboard
        1 Island
        Display Commander
        1 Kenrith, the Returned King
        Planar Deck
        1 Akoum
        Scheme Deck
        1 A Display of My Dark Power
        Tokens
        1 Soldier [token]
      DECK
      expect(deck.sections).to eq(
        "Commander" => [{name: "Atraxa, Praetors' Voice", count: 1}],
        "Main Deck" => [{name: "Forest", count: 1}],
        "Sideboard" => [{name: "Island", count: 1}],
        "Display Commander" => [{name: "Kenrith, the Returned King", count: 1}],
        "Planar Deck" => [{name: "Akoum", count: 1}],
        "Scheme Deck" => [{name: "A Display of My Dark Power", count: 1}],
        "Tokens" => [{name: "Soldier", count: 1, token: true}],
      )
    end

    it "accepts section headers with surrounding whitespace" do
      deck = parse_deck("// NAME: X\n  Sideboard \t\n1 Island\n")
      expect(deck.sections.keys).to eq(["Sideboard"])
    end

    it "treats unknown headers as card lines" do
      expect { parse_deck("// NAME: X\nMaybeboard\n1 Island\n") }.to raise_error(/no card name/)
    end

    it "routes COMMANDER: lines to Commander without changing current section" do
      deck = parse_deck(<<~DECK)
        // NAME: X
        COMMANDER: 1 Atraxa, Praetors' Voice [c16:28] [foil]
        1 Forest
      DECK
      expect(deck.sections).to eq(
        "Commander" => [{name: "Atraxa, Praetors' Voice", count: 1, set: "c16", number: "28", foil: true}],
        "Main Deck" => [{name: "Forest", count: 1}],
      )
    end

    it "reports the original line in errors for COMMANDER: lines" do
      expect { parse_deck("// NAME: X\nCOMMANDER: x Atraxa\n") }.to raise_error(/in line "COMMANDER: x Atraxa"/)
    end
  end

  describe "#section_sizes" do
    it "sums counts per section, excluding tokens" do
      deck = parse_deck(<<~DECK)
        // NAME: X
        20 Forest
        4 Llanowar Elves
        3 Elf Warrior [token]
        Sideboard
        2 Naturalize
        Scheme Deck
        1 Soldier [token]
      DECK
      expect(deck.section_sizes).to eq("Main Deck" => 24, "Sideboard" => 2, "Scheme Deck" => 0)
    end
  end

  describe "#merge_duplicates" do
    it "merges identical cards within a section" do
      deck = parse_deck("// NAME: X\n2 Forest\n1 Island\n3 Forest\n")
      deck.merge_duplicates
      expect(deck.sections["Main Deck"]).to eq([
        {name: "Forest", count: 5},
        {name: "Island", count: 1},
      ])
    end

    it "keeps cards with different printings or markers apart" do
      deck = parse_deck(<<~DECK)
        // NAME: X
        1 Forest [m20:277]
        1 Forest [m20:278]
        1 Forest [m20:277] [foil]
        1 Forest [m20:277]
      DECK
      deck.merge_duplicates
      expect(deck.sections["Main Deck"]).to eq([
        {name: "Forest", count: 2, set: "m20", number: "277"},
        {name: "Forest", count: 1, set: "m20", number: "278"},
        {name: "Forest", count: 1, set: "m20", number: "277", foil: true},
      ])
    end

    it "does not merge across sections" do
      deck = parse_deck("// NAME: X\n1 Forest\nSideboard\n1 Forest\n")
      deck.merge_duplicates
      expect(deck.sections).to eq(
        "Main Deck" => [{name: "Forest", count: 1}],
        "Sideboard" => [{name: "Forest", count: 1}],
      )
    end
  end
end
