# destinder-api
Complete rewrite of the back-end API for [Destinder LFG](https://www.destinder.com). Replaces the [Destinder v1 API](https://github.com/destiny-aviato/destinder).

[![Maintainability](https://api.codeclimate.com/v1/badges/6afa64ab9543b727fe51/maintainability)](https://codeclimate.com/github/destiny-aviato/destinder-api/maintainability) [![Test Coverage](https://api.codeclimate.com/v1/badges/6afa64ab9543b727fe51/test_coverage)](https://codeclimate.com/github/destiny-aviato/destinder-api/test_coverage)

## Installation Instructions

### Prerequisites
This app uses Ruby on Rails, so make sure you have both the Ruby programming language installed as well as the Rails gem.

### Setup
To run the app, you'll need to install its dependencies first, then boot it up.
1. Run `./bin/setup` to get the app bootstrapped

1. Run `foreman start`. This will start the server and automatically open a session at http://localhost:5000

### Updating
To update your repo with the latest changes for the client or other dependencies, you can use the premade script:

1. Run `./bin/update` to fetch the latest changes for the API and the client, updating any dependencies along the way.

## Contributing

We love and welcome all contribution requests! If you've either found a bug or have a feature you want added in, please create a pull request with a detailed comment outlining your changes (Follow [this guide](https://help.github.com/articles/fork-a-repo/)). Please also attach any screenshots of UI changes you may have made in the process as well. If you have any questions please file an issue on GitHub or send [send us an email](mailto:help@destinder.com). We plan on reviewing all pull requests within 2 weeks of submission. Thanks!
