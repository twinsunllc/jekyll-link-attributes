# frozen_string_literal: true

require 'jekyll-link-attributes/hooks'
require 'jekyll-link-attributes/version'
require 'nokogiri'
require 'uri'

module Jekyll

  # Adjusts external links in HTML documents.
  class LinkAttributes

    # Perform post_render processing on the specified document/page/post
    # @param [Object] article a Jekyll document, page, or post
    def self.post_render_html(article)
      config = article.site.config
      return unless external_links_enabled?(config: config)

      ext_config = config['external_links'] || {}
      utm_params = build_utm_params(ext_config: ext_config, site_config: config, article: article)

      output = Nokogiri::HTML(article.output)
      output.css('a').each do |a|
        next unless external_link?(config: config, url: a['href'])

        original_href = a['href']

        # UTM: applied to all external links with its own exclude list
        if utm_params && !excluded?(ext_config: ext_config, section: 'utm', url: original_href)
          a['href'] = append_utm_params(url: a['href'], utm_params: utm_params)
        end

        # rel: new-style section config falls back to legacy top-level keys
        unless a['rel']
          rel_value = resolve_value(ext_config: ext_config, section: 'rel', legacy_key: 'rel',
                                    default: 'external nofollow noopener')
          unless excluded?(ext_config: ext_config, section: 'rel', url: original_href)
            a['rel'] = rel_value
          end
        end

        # target: new-style section config falls back to legacy top-level keys
        unless a['target']
          target_value = resolve_value(ext_config: ext_config, section: 'target', legacy_key: 'target',
                                       default: '_blank')
          unless excluded?(ext_config: ext_config, section: 'target', url: original_href)
            a['target'] = target_value
          end
        end
      end

      article.output = output.to_s
    end

    private

    # Resolve value for a section, falling back to legacy top-level key.
    # New style: external_links.rel.value / external_links.target.value
    # Legacy:   external_links.rel / external_links.target (string value)
    def self.resolve_value(ext_config:, section:, legacy_key:, default:)
      section_config = ext_config[section]
      if section_config.is_a?(Hash)
        section_config['value'] || default
      else
        section_config || default
      end
    end

    # Check if a URL is excluded for a given section.
    # New style: external_links.<section>.exclude
    # Legacy fallback (rel/target only): external_links.exclude
    def self.excluded?(ext_config:, section:, url:)
      section_config = ext_config[section]
      excludes = if section_config.is_a?(Hash)
                   section_config['exclude'] || []
                 elsif section == 'utm'
                   []
                 else
                   ext_config['exclude'] || []
                 end

      excludes.any? { |pattern| Regexp.new("^#{pattern}$").match?(url) }
    end

    def self.external_link?(config:, url:)
      site_url = config['url']
      !(url =~ %r{^https?://}).nil? && (site_url.nil? || !url.start_with?(site_url))
    end

    def self.external_links_enabled?(config:)
      enabled = config.dig('external_links', 'enabled')
      enabled.nil? || enabled
    end

    def self.utm_enabled?(ext_config:)
      ext_config.dig('utm', 'enabled') == true
    end

    def self.build_utm_params(ext_config:, site_config:, article:)
      return nil unless utm_enabled?(ext_config: ext_config)

      utm_config = ext_config['utm'] || {}
      source = utm_config['source'] || site_config['url']&.sub(%r{\Ahttps?://}, '') || 'website'
      medium = utm_config['medium'] || 'website'

      campaign = case article.data['layout']
                 when 'post', 'blog' then 'blog'
                 else
                   path = article.url.to_s.gsub(%r{\A/|/\z}, '')
                   path.empty? ? 'homepage' : path.split('/').first
                 end

      content = article.data['slug'] || File.basename(article.url.to_s.chomp('/'))
      content = 'index' if content.empty?

      {
        'utm_source'   => source,
        'utm_medium'   => medium,
        'utm_campaign' => campaign,
        'utm_content'  => content,
      }
    end

    def self.append_utm_params(url:, utm_params:)
      uri = URI.parse(url)
      existing = URI.decode_www_form(uri.query || '').to_h
      utm_params.each { |k, v| existing[k] = v unless existing.key?(k) }
      uri.query = URI.encode_www_form(existing)
      uri.to_s
    rescue URI::InvalidURIError
      url
    end
  end
end
