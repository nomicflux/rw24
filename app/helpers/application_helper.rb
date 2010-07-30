# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def link_to_current(name, options = {}, html_options = {})
    url = case options
      when String
        options
      when :back
        @controller.request.env["HTTP_REFERER"] || 'javascript:history.back()'
      else
        self.url_for(options)
      end
    condition = html_options.delete(:if) || url == request.request_uri

    if condition
      if html_options[:class]
        html_options[:class] += ' current'
      else
        html_options[:class] = 'current'
      end
    end
    link_to name, options, html_options
  end
  
  def content_path(section, content)
    return article_path(section, content) if content.is_a? Article
    link_path(section, content)
  end

  def fixed_number_or_empty(value, options = { :size => 2 })
    return '-' * options[:size] unless value.nonzero?
    "%0#{options[:size]}d" % value 
  end
end
