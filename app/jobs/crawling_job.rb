class CrawlingJob
  include Sidekiq::Worker
  sidekiq_options unique: :while_executing

  def perform(id)
    source = LinkSource.find_by(id: id)
    return unless source.present?

    10.times do
      break if crawl!(source)
      sleep(1.0/2.0)
    end
  end

  def crawl!(source)
    data = fetch_data(source)
    return false unless valid_open_graph?(data)
    source.set_crawling_data(data)

    ActiveRecord::Base.transaction do
      if source.url != data.url
        origin = LinkSource.where(url: data.url).oldest
        if origin.blank?
          source.url = data.url
          source.set_crawling_data(data)
          source.save!
          marge_targets = source.articles.to_a
          source.articles.update_all(link: source.url)
          marge_targets.each { |article| Article.merge_by_link!(article.reload) }
        else
          origin.set_crawling_data(data)
          origin.save!
          marge_targets = source.articles.to_a
          source.articles.update_all(link_source_id: origin.id, link: origin.url)
          marge_targets.each { |article| Article.merge_by_link!(article.reload) }
          source.destroy!
        end

      else
        source.set_crawling_data(data)
        source.save!
      end
    end
  end

  def fetch_data(source)
    OpenGraph.new(source.url, {headers: {'Accept-Language' => 'ko-KR,ko;q=0.8,en-US;q=0.6,en;q=0.4'}})
  end

  def valid_open_graph?(data)
    data.present? and data.title.present? and data.title != data.src
  end
end
