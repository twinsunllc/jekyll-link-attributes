# frozen_string_literal: true

require 'jekyll-link-attributes'

describe Jekyll::LinkAttributes do
  before :each do
    @config = {
      'url' => 'https://config.example.com',
      'external_links' => {
        'enabled' => true,
        'rel' => 'external nofollow noopener',
        'target' => '_blank',
        'exclude' => %w[
          https://exclude.example.com
          https://regex.example.com/.+
        ]
      }
    }
  end

  it 'has a version number' do
    expect(Jekyll::LinkAttributes::VERSION).not_to be nil
  end

  it 'uses default values if no configuration is provided' do
    expect(Jekyll::LinkAttributes.external_links_enabled?(config: {})).to be true
    expect(Jekyll::LinkAttributes.external_link_rel(config: {})).to eq('external nofollow noopener')
    expect(Jekyll::LinkAttributes.external_link_target(config: {})).to eq('_blank')
    expect(Jekyll::LinkAttributes.excludes_external_link?(config: {}, url: 'https://exclude.example.com')).to be false
  end

  it 'detects external links' do
    expect(Jekyll::LinkAttributes.external_link?(config: @config, url: 'http://www.twinsunsolutions.com')).to be true
    expect(Jekyll::LinkAttributes.external_link?(config: @config, url: 'https://www.twinsunsolutions.com')).to be true
    expect(Jekyll::LinkAttributes.external_link?(config: @config, url: '/blog')).to be false
    expect(Jekyll::LinkAttributes.external_link?(config: @config, url: 'contact')).to be false

    # absolute link to our own site host; don't treat as an external link.
    expect(Jekyll::LinkAttributes.external_link?(config: @config, url: 'https://config.example.com')).to be false
  end

  it 'detects excluded external links' do
    expect(Jekyll::LinkAttributes.excludes_external_link?(config: @config, url: 'https://exclude.example.com')).to be true
    expect(Jekyll::LinkAttributes.excludes_external_link?(config: @config, url: 'https://exclude.example.com/nope')).to be false
    expect(Jekyll::LinkAttributes.excludes_external_link?(config: @config, url: 'https://include.example.com')).to be false

    expect(Jekyll::LinkAttributes.excludes_external_link?(config: @config, url: 'https://regex.example.com/excluded')).to be true
    expect(Jekyll::LinkAttributes.excludes_external_link?(config: @config, url: 'https://regex.example.com')).to be false
  end

  it 'detects external links enabled' do
    expect(Jekyll::LinkAttributes.external_links_enabled?(config: @config)).to be true
    @config['external_links']['enabled'] = false
    expect(Jekyll::LinkAttributes.external_links_enabled?(config: @config)).to be false
  end

  it 'determines external link rel' do
    expect(Jekyll::LinkAttributes.external_link_rel(config: @config)).to eq('external nofollow noopener')
    @config['external_links']['rel'] = 'external'
    expect(Jekyll::LinkAttributes.external_link_rel(config: @config)).to eq('external')
  end

  it 'determines external link target' do
    expect(Jekyll::LinkAttributes.external_link_target(config: @config)).to eq('_blank')
    @config['external_links']['target'] = '_self'
    expect(Jekyll::LinkAttributes.external_link_target(config: @config)).to eq('_self')
  end
end
