# frozen_string_literal: true

require 'jekyll/hooks'
require 'jekyll-link-attributes'

Jekyll::Hooks.register :documents, :post_render do |document|
  Jekyll::LinkAttributes.post_render_html(document)
end

Jekyll::Hooks.register :pages, :post_render do |page|
  next unless page.output_ext.eql?('.html')

  Jekyll::LinkAttributes.post_render_html(page)
end

Jekyll::Hooks.register :posts, :post_render do |post|
  Jekyll::LinkAttributes.post_render_html(post)
end
