# README

This README details a Treasure Hunt Game backend that users can use to take part in a treasure hunt. 

Administrators first set up treasure hunts via the Treasures API, specifying a location validated by the Geocoder library (https://github.com/alexreisner/geocoder) to act as the location of a prospective treasure. Users taking part in the hunt can then leave guesses via the Guesses API. If their guess is within 1000m of the treasure, they will receive an email telling them that they've won. This will automatically displayed in the user's browser through the use of the Letter Opener library (https://github.com/ryanb/letter_opener).

The application also comes with a pre-defined Swagger spec (created with RSwag: https://github.com/rswag/rswag) which will render at http://localhost:3000/api-docs when it is run. Calls can be made to the API through this UI for testing.

Pre-requisites
==============
* Ruby 2.7.7p221
* Rails 7.0.8.1
* Postgres 14.9

Other Dependencies
==================
* Geocoder
* Letter Opener
* RSwag

Setup
=====

To set up the application, do the following:

* Install and start Postgres: https://www.postgresql.org/download/
* Create a new user in your Postgres DB which will run the Treasure Hunt app DBs (development and test):

```
CREATE ROLE treasure_hunt LOGIN CREATEDB;
```

* Log out of Postgres and log back in with this user:

```
psql postgres -U treasure_hunt
```

* Run the following commands:

```
CREATE DATABASE treasure_hunt;
CREATE DATABASE treasure_hunt_test;
```

* Check out the app repo from a clone location of your choice (see above).
* In the app root, install the gem dependencies:

```
bundle
```

* Create the DB schema for both development and test environments:

```
./bin/rails db:migrate
RAILS_ENV=test ./bin/rails db:migrate
```

* Run the application.

```
./bin/rails s
```

* Navigate to http://localhost:3000/api-docs to view / test the interactive Swagger documentation.
* There is also an integration test suite available which covers the function of each API endpoint. This can run with the standard RSpec command:

```
rake spec
```

