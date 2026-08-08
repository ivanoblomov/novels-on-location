# Novels: On Location

[![test](https://github.com/ivanoblomov/novels-on-location/actions/workflows/test.yml/badge.svg)](https://github.com/ivanoblomov/novels-on-location/actions/workflows/test.yml)
[![Maintainability](https://qlty.sh/gh/ivanoblomov/projects/novels-on-location/maintainability.svg)](https://qlty.sh/gh/ivanoblomov/projects/novels-on-location)

*[Novels: On Location](https://NovelsOnLocation.com)* is a Google Maps & Books mash-up for finding novels that take place where you're traveling. Browse or search the map and make your next destination come alive!

## Running locally

### Restart web server

```sh
puma-dev -stop
```

### Tail log and watch assets for edits

```sh
bin/dev
```

## Database

### Start MongoDB

```sh
brew services start mongodb/brew/mongodb-community
```

### Connect to remote DB

```sh
mongosh ds035735.mlab.com:35735/heroku_1gh6pvr9 -u heroku_1gh6pvr9 -p heroku_1gh6pvr9
```

### Back-up remote DB

```sh
mongodump -h ds035735.mlab.com:35735 -d heroku_1gh6pvr9 -u heroku_1gh6pvr9 -p heroku_1gh6pvr9 -o ./db/backups/novels
```

### Restore DB locally

sh:
```sh
mongosh
```
mongosh:
```js
use novels
db.dropDatabase()
```
sh:
```sh
mongorestore --db novels db/backups/heroku_1gh6pvr9/
```
