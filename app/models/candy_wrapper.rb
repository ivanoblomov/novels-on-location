class CandyWrapper
  def self.book keyword
    r = open(
      :operation => 'ItemSearch',
      :search_index => 'Books',
      :keywords => keyword
    )

    book = {
      :asin => r.find('ASIN').first,
      :author => r.find('Author').first,
      :title => r.find('Title').first,
      :url => r.find('DetailPageURL').first
    }

    return if book.blank? || book[:asin].blank?
    book.merge(thumbnail(book[:asin])).merge(review book[:asin])
  end

  def self.review asin
    r = open(
      :operation      => 'ItemLookup',
      :id_type        => 'ASIN',
      :item_id        => asin,
      :response_group => 'EditorialReview'
    )

    e = r.find('EditorialReview')
    return {} if e.blank?
    {:review => e[0]['Content']}
  end

  def self.thumbnail asin
    r = open(
      :operation      => 'ItemLookup',
      :id_type        => 'ASIN',
      :item_id        => asin,
      :response_group => 'Images'
    )

    i = r.find('ThumbnailImage')[0]
    return {} if i.blank?

    {
      :image_url => i['URL'],
      :image_width => i['Width']['__content__'],
      :image_height => i['Height']['__content__']
    }
  end

  private

  def self.open request
    s = Sucker.new
    s << request
    s.get
  end
end
