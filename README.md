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
* FactoryBot
* will_paginate

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

![Screenshot 2024-03-12 at 01 17 15](https://github.com/nickf/treasure-hunt/assets/33024/58ea7051-3b24-4cfa-bb12-da426d1e633a)

Endpoints
=========
The API contains the following endpoints:

* `POST /treasures` - Create a new treasure hunt location.
* `GET /treasures/{id}/winners` - Get the list of winning guesses on a treasure hunt. Can be sorted and paginated.
* `PUT /treasures/{id}/deactivate` - deactivate a treasure hunt so that no more guesses can be made.
* `DELETE /treasures/{id}` - deletes a treasure location, and cascade deletes its related guesses.
* `POST /guesses` - Submit a guess for a given treasure hunt location. Send an email if the guess is a winning guess (within 1000m of treasure).

For details on the attributes, please see the Swagger documentation and the Starting A Game section below.

Starting A Game
===============
* To begin, find a street address (either on Google Maps or elsewhere) to serve as a treasure location. **NOTE:** Only a full street address can be specified. This is to make it easier to create treasure hunts + guesses without Geocoder's own address validation failing.
* Create a new treasure by making a POST request to /treasures, specify an `answer` attribute as your treasure location as a string value.
* Then, attempt a guess using the ID of the treasure, an alternative street address for the attempted `answer`, and an `email` address of your choice. The request body should look something like:

```
{
  "treasure_id": 1,
  "answer": "1234 Other St., Los Angeles, CA 90249",
  "email": "test-user@example.com"
}
```

As mentioned, some attempts to create treasure / guesses by address might fail Geocoder's validation to get valid coordinates. This is something I would have liked to look into further had I more time (see Further Considerations below).

* If your guess is valid and within 1000m of the treasure location, you should see a browser tab open showing the email that would be sent if the application was tied up to proper SMTP configuration.
* If the guess is not within 1000m, you will still receive a 201 API response, but no email message.

Other Notes
===========
* As mentioned, Geocoder is responsible for location validation on both treasure + guess street addresses, and also for the setting of coordinates for valid locations. For more information please refer to the Geocoder documentation: https://github.com/alexreisner/geocoder?tab=readme-ov-file#geocoding-objects
* Distance calculation is leveraged using Geocoder's `#distance_between` method that compares differing lat-long coordinate pairs.

Further Considerations
======================
* By default, Geocoder's default lookup for address validation is Nominatim, which given testing appears to be somewhat flaky. I would have liked to have spent more time exploring other third-party libraries that can integrate with this gem (particularly Google Maps), but have submitted due to time constraints.
* The integration tests should cover all API function. Unit tests were skipped for some of the model functions but would have been added if more time allowed.
* Finding a way to mock Geocoder's underlying #geocode call in tests.
* Some refactoring of variable re-use, particularly in the integration tests, would have also been nice had I had the time.
