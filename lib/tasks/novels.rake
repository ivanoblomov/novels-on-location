namespace :novels do
  SLUG_REGEX = %r{http://novelsonlocation.com/locations/(.+)}
  TWEET_REGEX = /A fan just pinned "(.+)" to (.+). Learn more at (.+) #lp/

  desc 'Restore Locations from Twitter feed'
  task restore: :environment do
    @twitter_client = Twitter::REST::Client.new do |config|
      config.consumer_key = 'Ms7Cl2g9eM0sZKRl8YA34Q'
      config.consumer_secret = 'gQlXn8I9TtLcNSepF5D59DBkSI0Wv9pYl1465iAc4'
      config.access_token = '490732052-SDJHy8huJ9J4Ic7aNIiR4T4XZiBxbMQ2eW2Qi2oz'
      config.access_token_secret = 'N8B6ZPg0gxtqLOeEI7LVKbHCdXvZpHJqpRmmPNSWk'
    end

    coder = HTMLEntities.new
    invalid = []
    locations = []
    skipped = []
    tweets = @twitter_client.user_timeline 'NovelsOnLoc'

    tweets.each do |tweet|
      matches = TWEET_REGEX.match coder.decode tweet.text

      if matches
        title = matches[1]
        place = matches[2]
        short_url = matches[3]
        url = Embiggen::URI(short_url).expand timeout: 10
        slug = url.to_s.split('/').try :last
        location = Location.new book_keywords: title,
                                tags: place
        location.valid?

        if location.errors.present?
          invalid << {
            location: location,
            slug: slug,
            tweet: tweet
          }
        else
          locations << location
        end
      else
        skipped << tweet
      end
      sleep 1.0
    end

    puts "Found #{locations.size} locations:\n"
    puts locations.map(&:to_s)
    puts "\nCan't save #{invalid.size} locations:"
    puts "#{(
      invalid.map do |h|
        [
          h[:location].errors.full_messages * ', ',
          TWEET_REGEX.match(h[:tweet].text).to_a[1..-1]
        ] * ' => '
      end
    ) * "\n"}"
    puts "\nSkipped #{skipped.size} tweets"
    puts skipped.map(&:text)
  end
end
