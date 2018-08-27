class Tweet < ActiveRecord::Base

  self.per_page = 20

  belongs_to :user
  belongs_to :parent, class_name: "Tweet"
  has_many :replies, class_name: "Tweet", foreign_key: "parent_id"
  has_many :favorites
  has_many :retweets, foreign_key: "source_tweet_id"
  validates :tweet_text, presence: true, length: { maximum: 140 }

  counter_culture :user

  mount_uploader :media, MediaUploader

  before_save :do_before_save

  def do_before_save
    fetch_image
    short_url
  end

  def fetch_image
    if (url=self.urls.first)
      response = Tweet.get_image(url)
      if response['status'] == 'ok' and response['image'].present?
        self.image_url = response['image']
      else
        self.image_url = nil
      end
    end
  end

  def short_url
    pattern = /(\s|^)(http[s]*:\/\/[a-z0-9.\/?=%:_&~-]+)(\s|$)/i
    if (self.tweet_text.to_s =~ pattern).nil?
      return
    end

    original = self.tweet_text
    begin
      segments = self.tweet_text.split(pattern)
      shorteds = segments.collect{ |text|
        
        if text.start_with?("http")
          resp = Tweet.call_short(text)
          if resp['status'] == 'ok'
            resp['url']
          else
            text
          end
        else
          text
        end 
      }
      self.tweet_text = shorteds.join(" ")
    rescue Exception => e
      self.tweet_text = original
    end
  end

  def urls
    pattern = /(\s|^)(http[s]*:\/\/[a-z0-9.\/?=%:_&~-]+)(\s|$)/i
    addrs = []
    if (self.tweet_text.to_s =~ pattern).nil?
      return []
    end
    segments = self.tweet_text.split(pattern)
    segments.each do |text|        
      if text.start_with?("http")
        addrs << text
      end 
    end
    return addrs 
  end
  
  def self.call_short(url)
    host = (Rails.env == 'development')? 'http://localhost:9393' : 'http://s.snppt.com'
    resp = Faraday.post("#{host}/api_url?long_url=#{url}")
    JSON.parse(resp.body)
  end

  def self.get_image(url)
    begin
      page = MetaInspector.new(url)
      return {'status' => 'ok', 'image' => page.images.best}
    rescue Exception => e
      return {'status' => 'error'}
    end

  end
end
