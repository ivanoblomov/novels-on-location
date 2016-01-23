namespace :novels do
  SLUG_REGEX = %r{http://novelsonlocation.com/locations/(.+)}
  TWEET_REGEX = %r{A fan just pinned "(.+)" to (.+). Learn more at (.+) #lp}

  desc 'Restore Locations from Twitter feed'
  task restore: :environment do
    @twitter_client = Twitter::REST::Client.new do |config|
      config.consumer_key = 'Ms7Cl2g9eM0sZKRl8YA34Q'
      config.consumer_secret = 'gQlXn8I9TtLcNSepF5D59DBkSI0Wv9pYl1465iAc4'
      config.access_token = '490732052-SDJHy8huJ9J4Ic7aNIiR4T4XZiBxbMQ2eW2Qi2oz'
      config.access_token_secret = 'N8B6ZPg0gxtqLOeEI7LVKbHCdXvZpHJqpRmmPNSWk'
    end

    invalid = []
    locations = []
    skipped = []
    tweets = @twitter_client.user_timeline 'NovelsOnLoc'

    tweets.each do |tweet|
      matches = TWEET_REGEX.match tweet.text

      if matches
        novel = matches[1]
        place = matches[2]
        short_url = matches[3]
        url = Embiggen::URI(short_url).expand
        location = Location.new book_keywords: novel,
                                tags: place
        location.valid?

        if location.errors.present?
          p [novel, place]
          invalid << tweet
        else
          locations << location
        end
      else
        skipped << tweet
      end
    end

    p "Can restore #{locations.size} locations"
    p "Can't save #{invalid.size} locations"
    p "Skipped #{skipped.size} tweets"
  end
end
