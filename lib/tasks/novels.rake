# frozen_string_literal: true

SLUG_REGEX = %r{http://novelsonlocation.com/locations/(.+)}
TWEET_REGEX = /A fan just pinned "(.+)" to (.+). Learn more at (.+) #lp/

# rubocop:disable Metrics/BlockLength
namespace :novels do
  desc 'Update Locations with Google Books info'
  task update_with_google_books: :environment do
    changed_set = Set.new
    total = Location.missing_isbn.count
    updated = 0
    puts "Found #{total} Locations."
    Location.missing_isbn.each_with_index do |location, index|
      response = GoogleBooks.search(location.send(:search_terms))
      book = response.first
      if book
        location.send :update_from_google_book, book
      elsif response.instance_variable_get(:@response)['totalItems']&.zero?
        puts "Can't find anything matching #{location.send(:search_terms)} for #{location}"
        next
      else
        abort response.instance_variable_get(:@response)['error']['message']
      end
      sleep(0.1) && next unless location.changed?

      changed = location.changed
      changed_set.merge changed
      changes = location.changes
      if location.save
        updated += 1
        puts "#{updated}/#{total - index - 1} Updated #{changes} for #{location}"
      else
        puts "Can't save #{location.errors.full_messages}"
      end
    end
    puts "Updated #{changed_set.to_a * ', '} in #{updated} out of #{total} Locations."
  end

  desc 'Restore Locations from Twitter feed'
  task restore: :environment do
    coder = HTMLEntities.new
    tweeted_locations = []
    skipped = []
    tweets = TWITTER_CLIENT.user_timeline 'NovelsOnLoc'

    tweets.each do |tweet|
      matches = TWEET_REGEX.match coder.decode tweet.text

      if matches
        title = matches[1]
        place = matches[2]
        short_url = matches[3]
        url = Embiggen::URI(short_url).expand timeout: 10
        slug = url.to_s.split('/').try :last

        tweeted_location = TweetedLocation.create place: place,
                                                  slug: slug,
                                                  text: tweet.text,
                                                  title: title
        tweeted_locations << tweeted_location if tweeted_location.persisted?
      else
        skipped << tweet
      end
      sleep 1.0
    end

    puts "Found #{tweeted_locations.count} TweetedLocations:\n"
    puts tweeted_locations.map(&:to_s)
    puts "\nSkipped #{skipped.size} tweets"
    puts skipped.map(&:text)
  end
end
# rubocop:enable Metrics/BlockLength
