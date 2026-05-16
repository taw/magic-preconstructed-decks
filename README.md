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
