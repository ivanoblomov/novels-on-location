# Wrapper for Sucker https://github.com/ryanmarshall/sucker
class CandyWrapper
  def self.book(keyword)
    book = first_book open search_args keyword
    return if book.blank? || book[:asin].blank?
    book.merge(thumbnail(book[:asin])).merge(review book[:asin])
  end

  def self.review(asin)
    e = response_group(asin, 'EditorialReview').find('EditorialReview')
    return {} if e.blank?
    { review: e[0]['Content'] }
  end

  def self.thumbnail(asin)
    i = response_group(asin, 'Images').find('ThumbnailImage')[0]
    return {} if i.blank?

    {
      image_url: i['URL'],
      image_width: i['Width']['__content__'],
      image_height: i['Height']['__content__']
    }
  end

  def self.first_book(response)
    {
      asin: response.find('ASIN').first,
      author: response.find('Author').first,
      title: response.find('Title').first,
      url: response.find('DetailPageURL').first
    }
  end
  private_class_method :first_book

  def self.open(request)
    s = Sucker.new
    s << request
    s.get
  end
  private_class_method :open

  def self.response_group(asin, response_group)
    open(
      operation: 'ItemLookup',
      id_type: 'ASIN',
      item_id: asin,
      response_group: response_group
    )
  end
  private_class_method :response_group

  def self.search_args(keyword)
    {
      operation: 'ItemSearch',
      search_index: 'Books',
      keywords: keyword
    }
  end
  private_class_method :search_args
end
