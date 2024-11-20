# Novels: On Location

[![Build status](https://github.com/ivanoblomov/novels-on-location/workflows/test/badge.svg)](https://github.com/ivanoblomov/novels-on-location/actions/workflows/test.yml)
[![Build status](https://github.com/ivanoblomov/novels-on-location/workflows/test/badge.svg)](https://github.com/ivanoblomov/novels-on-location/actions/workflows/test.yml)
[![test](https://github.com/ivanoblomov/novels-on-location/actions/workflows/test.yml/badge.svg)](https://github.com/ivanoblomov/novels-on-location/actions/workflows/test.yml)
[![test](https://github.com/ivanoblomov/novels-on-location/workflows/test/badge.svg)](https://github.com/ivanoblomov/novels-on-location/actions/workflows/test.yml)
<!--
[![Maintainability](https://api.codeclimate.com/v1/badges/9818a986253d2a477bb8/maintainability)](https://codeclimate.com/github/ivanoblomov/novels-on-location/maintainability)
[![Coverage Status](https://coveralls.io/repos/github/ivanoblomov/novels-on-location/badge.svg?branch=main&kill_cache=1)](https://coveralls.io/github/ivanoblomov/novels-on-location?branch=main)
 -->

## Back-up DB

```bash
mongo ds035735.mlab.com:35735/heroku_1gh6pvr9 -u heroku_1gh6pvr9 -p heroku_1gh6pvr9
mongodump -h ds035735.mlab.com:35735 -d heroku_1gh6pvr9 -u heroku_1gh6pvr9 -p heroku_1gh6pvr9 -o ./db/backups/novels
```

## Restore DB locally

```bash
mongorestore --db novels db/backups/heroku_1gh6pvr9/
```
