# frozen_string_literal: true

require 'jekyll-link-attributes/hooks'
require 'jekyll-link-attributes/version'
require 'nokogiri'

module Jekyll

  # Adjusts external links in HTML documents.
  class LinkAttributes

    # Perform post_render processing on the specified document/page/post
    # @param [Object] article a Jekyll document, page, or post
    def self.post_render_html(article)
      config = article.site.config
      return unless external_links_enabled?(config: config)

      output = Nokogiri::HTML(article.output)
      output.css('a').each do |a|
        next unless external_link?(config: config, url: a['href'])
        next if excludes_external_link?(config: config, url: a['href'])

        # only set rel and target if they're not already set
        a['rel'] = external_link_rel(config: config) unless a['rel']
        a['target'] = external_link_target(config: config) unless a['target']
      end

      article.output = output.to_s
    end

    private

    def self.excludes_external_link?(config:, url:)
      excludes = (config.dig('external_links', 'exclude') || [])
      excludes.any? { |exclude| Regexp.new("^#{exclude}$").match? url }
    end

    def self.external_link?(config:, url:)
      site_url = config['url']
      !(url =~ %r{^https?://}).nil? && (site_url.nil? || !url.start_with?(site_url))
    end

    def self.external_links_enabled?(config:)
      enabled = config.dig('external_links', 'enabled')
      enabled.nil? || enabled
    end

    def self.external_link_rel(config:)
      config.dig('external_links', 'rel') || 'external nofollow noopener'
    end

    def self.external_link_target(config:)
      config.dig('external_links', 'target') || '_blank'
    end
  end
end
