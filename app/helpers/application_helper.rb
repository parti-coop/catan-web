module ApplicationHelper
  def byline(user, options={})
    return if user.nil?
    raw render(partial: 'users/byline', locals: options.merge(user: user))
  end

  def icon(classes)
    content_tag(:i, nil, class: classes)
  end

  def date_f(date)
    if date.today?
      date.strftime("%H:%M")
    else
      date.strftime("%Y.%m.%d")
    end
  end

  def striped_smart_format(text, html_options = {}, options = {})
    smart_format(strip_tags(text), html_options, options)
  end

  def smart_format(text, html_options = {}, options = {})
    auto_link(simple_format(text, html_options, options),
      html: {class: 'auto_link', target: '_blank'},
      link: :urls)
  end

  def asset_data_base64(path)
    content, content_type = parse_asset(path)
    base64 = Base64.encode64(content).gsub(/\s+/, "")
    "data:#{content_type};base64,#{Rack::Utils.escape(base64)}"
  end

  def parse_asset(path)
    if Rails.application.assets
      asset = Rails.application.assets.find_asset(path)
      throw "Could not find asset '#{path}'" if asset.nil?
      return asset.to_s, asset.content_type
    else
      name = Rails.application.assets_manifest.assets[path]
      throw "Could not find asset '#{path}'" if name.nil?
      content_type = MIME::Types.type_for(name).first.content_type
      content = open(File.join(Rails.public_path, 'assets', name)).read
      return content, content_type
    end
  end
end
