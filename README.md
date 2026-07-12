To generate json file:

    bundle install
    bundle exec bin/build_jsons decks.json

### Adding new sets

To add new decks from new set:

* use `url2txt` from taw/mtg repo to fetch decklists
* move decklists to right repository
* use `bundle exec bin/build_jsons decks.json` to validate file structure
* use `bundle exec bin/validate_card_names` to validate card names

CI will do validation for you if you open a PR.

### Card set annotations

Every card that comes from a set **different from the deck's own set** must be
annotated with `[SETCODE]` (or `[SETCODE:number]` when a specific printing is
needed); a trailing `[foil]` may follow. Cards from the deck's own set need no
annotation. For example, an Avatar Eternal (`TLE`) card inside an Avatar (`TLA`)
deck is written `1 Thriving Heath [TLE]`. The set-only form is enough when the
card has a single printing in that set. The indexer can sometimes infer a
cross-set printing on its own, but annotating it explicitly is required — it
otherwise errors (`No Standard legal printing found`) or silently guesses.
