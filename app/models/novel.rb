class Novel
  include Mongoid::Document

  field :asin
  field :author
  field :title

  def self.look_up(title)
    request = Sucker.new(
      :locale => :us,
      :key => Rails.application.config.amazon_access_key_id,
      :secret => Rails.application.config.amazon_secret_access_key
    )

    request << {
      'Operation' => 'ItemSearch',
      'SearchIndex' => 'Books',
      'Keywords' => title
    }

    response = request.get

    Novel.new :asin => response.find('ASIN').first, :author => response.find('Author').first, :title => response.find('Title').first
  end
end
