# AGENTS.md

Plain-text decklists of preconstructed Magic: The Gathering products, compiled
into `decks.json` (consumed by the sibling `magic-search-engine` repo).

## Layout

- `data/<deck-type>/<set-code>/<Deck Name>.txt`: one file per deck. Deck types
  are defined in `lib/deck_types.yaml` (category, format, section size limits).
  A trailing `_` on the set dir (e.g. `sld_`) is stripped when reading the set code.
- `lib/deck.rb`: deck file parser. `lib/sets.rb` is generated (`rake sets`).
  `lib/valid_card_names.txt` is the card name whitelist, updated by hand.
- `bin/`: `build_jsons`, `validate_metadata`, `validate_card_names`, plus helpers
  (`resolve_card`, `annotate_date`, `annotate_default_date`,
  `make_file_names_match_metadata`). Some helpers expect sibling repos
  checked out under `~/github/`.
- `spec/`: rspec tests for the parser and deck types.

## Deck file format

```
// NAME: Deck Name              (must match filename; "/" becomes "-", ": " can be "- ")
// SOURCE: https://...          (one or more; required)
// DATE: YYYY-MM-DD
// DISPLAY: note shown to users (optional, repeatable)
// COMMENTS: internal note      (optional)
2 Card Name
1 Card Name [SET:123] [foil]
COMMANDER: 1 Legend Name [SET:45]

Sideboard
1 Soldier [SET:3] [token]
```

- Sections: `Main Deck` (default), `Sideboard`, `Commander`, `Display Commander`,
  `Planar Deck`, `Scheme Deck`, `Tokens`.
- Cards from a set other than the deck's own set **must** be annotated
  `[SET]` or `[SET:number]`. Use `[SET:*]` for "any basic land printing" when the
  exact one is unknown. Flags: `[foil]`, `[etched]`, `[token]`.
- Tokens, helper cards, blank/support cards and other inserts go in the owning
  deck's `Sideboard` with `[token]` where applicable (not a separate addon deck).
- Product variants with different contents get separate files, named
  consistently (e.g. original one as "Variant A").
- Preserve collector-number order where the source lists it (e.g. Secret Lair).
- Dates: use the best-supported real date; a plausible specific date beats the
  set's default release date when that default is clearly wrong.

## Validation (run before finishing; Semaphore CI runs all but `validate_metadata`)

```
bundle exec rspec
bundle exec bin/build_jsons decks.json
bundle exec bin/validate_card_names
bundle exec bin/validate_metadata
```

## Working conventions

- Only add data you can verify from a source (official lists, product scans,
  reliable wikis); cite it in `// SOURCE:`. Note doubts in `// COMMENTS:`
  rather than guessing silently.
- Don't edit generated files (`lib/sets.rb`, `decks.json`) by hand.
