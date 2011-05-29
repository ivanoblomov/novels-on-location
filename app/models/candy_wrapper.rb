class CandyWrapper
  def self.findBook( value )
    r = self.open(
      {
        'Operation' => 'ItemSearch',
        'SearchIndex' => 'Books',
        'Keywords' => value
      }
    )
  end

  private

  def self.open( request )
    s = Sucker.new(
      :locale => :us,
      :key => Rails.application.config.amazon_access_key_id,
      :secret => Rails.application.config.amazon_secret_access_key
    )

    s << request
    s.get
  end
end
