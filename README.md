# destinder-api
Complete rewrite of the back-end API for [Destinder LFG](https://www.destinder.com). Replaces the [Destinder v1 API](https://github.com/destiny-aviato/destinder).

[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/destiny-aviato/destinder-api/master/LICENSE)
[![Build Status](https://travis-ci.org/destiny-aviato/destinder-api.svg?branch=master)](https://travis-ci.org/destiny-aviato/destinder-api) [![Maintainability](https://api.codeclimate.com/v1/badges/6afa64ab9543b727fe51/maintainability)](https://codeclimate.com/github/destiny-aviato/destinder-api/maintainability) [![Test Coverage](https://api.codeclimate.com/v1/badges/6afa64ab9543b727fe51/test_coverage)](https://codeclimate.com/github/destiny-aviato/destinder-api/test_coverage)

## Installation Instructions

### Prerequisites
This app uses Ruby on Rails, so make sure you have both the Ruby programming language installed as well as the Rails gem.

### Setup
To run the app, you'll need to install its dependencies (rails, postgres) first, then boot it up.

1. Install gems `bundle install`
2. Setup figaro for env varialbles: `bundle exec figaro install`
3. Create the database: `rake db:create`
4. Migrate the database: `rake db:migrate`
5. Head to [Bungie's Application Portal](https://www.bungie.net/en/Application/) and create a new application with (Select OAuth client type of `Confidential`, use the `REDIRECT_URL` shown below, add `*` as the origin header, and select all permissions). This will generate a client ID, API key, and a client secret. Copy the all down and the following data to `application.yml`:

```ruby
JWT_SECRET: <random_secret:string>
CLIENT_ID: <client_id:string>
CLIENT_SECRET: <client_secret:string>
X_API_KEY: <api_key_from_bungie:string>
REDIRECT_URL: "https://brianbolnick-dev-redirect.herokuapp.com/auth/bungie"
API_TOKEN: <api_key_from_bungie:string>
DESTINDER_CLIENT_URL: "http://localhost:3000/"
BUNGIE_ACCESS_TOKEN_URL: "https://www.bungie.net/Platform/App/OAuth/Token/"
```

It should look something like this when complete:

```ruby
JWT_SECRET: "khas98yw3ouasod8wpi3hdpas9uoasihfo9q3dq"
CLIENT_ID: "12345"
CLIENT_SECRET: "csi83honc9s12jp9daS_@oa82o81!~9dsufjqp9"
X_API_KEY: "912087pdmo92u8qu0ac9u2"
REDIRECT_URL: "https://brianbolnick-dev-redirect.herokuapp.com/auth/bungie"
API_TOKEN: "912087pdmo92u8qu0ac9u2"
DESTINDER_CLIENT_URL: "http://localhost:3000/"
BUNGIE_ACCESS_TOKEN_URL: "https://www.bungie.net/Platform/App/OAuth/Token/"
```

6. Start the server: `rails s -p 5000`
7. Start jobs: `bundle exec rake jobs:work`



NOTE: If you receive the following error at any point: 

```
Is the server running locally and accepting connections on Unix domain socket "/tmp/.s.PGSQL.5432"?
```
You need to restart the postgres server, or remove the postgres pid file like so:

`rm /usr/local/var/postgres/postmaster.pid`

### Updating
To update your repo with the latest changes for the client or other dependencies, you can use the premade script:

1. Run `./bin/update` to fetch the latest changes for the API and the client, updating any dependencies along the way.

## Contributing

We love and welcome all contribution requests! If you've either found a bug or have a feature you want added in, please create a pull request with a detailed comment outlining your changes (Follow [this guide](https://help.github.com/articles/fork-a-repo/)). Please also attach any screenshots of UI changes you may have made in the process as well. If you have any questions please file an issue on GitHub or send [send us an email](mailto:help@destinder.com). We plan on reviewing all pull requests within 2 weeks of submission. Thanks!
