To generate json file:

    bundle install
    bundle exec bin/build_jsons decks.json

### Adding new sets

To add new decks from new set:

* add set code to `lib/sets.rb`
* use url2txt from taw/mtg repo to fetch decklists
* move decklists to right repository
* use `bundle exec bin/build_jsons decks.json` to validate
