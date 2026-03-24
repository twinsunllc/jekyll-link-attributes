# frozen_string_literal: true

require 'jekyll-link-attributes'

describe Jekyll::LinkAttributes do
  # ── Helpers ──────────────────────────────────────────────

  def make_article(output:, layout: 'default', slug: nil, url: '/')
    site = double('site', config: @config)
    data = { 'layout' => layout }
    data['slug'] = slug if slug
    article = double('article', site: site, output: output, output_ext: '.html', data: data, url: url)
    allow(article).to receive(:output=) { |v| allow(article).to receive(:output).and_return(v) }
    article
  end

  # ── Legacy config (v1 style) ─────────────────────────────

  describe 'legacy configuration' do
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
    end

    it 'detects external links' do
      expect(Jekyll::LinkAttributes.external_link?(config: @config, url: 'http://www.twinsunsolutions.com')).to be true
      expect(Jekyll::LinkAttributes.external_link?(config: @config, url: 'https://www.twinsunsolutions.com')).to be true
      expect(Jekyll::LinkAttributes.external_link?(config: @config, url: '/blog')).to be false
      expect(Jekyll::LinkAttributes.external_link?(config: @config, url: 'contact')).to be false
      expect(Jekyll::LinkAttributes.external_link?(config: @config, url: 'https://config.example.com')).to be false
    end

    it 'detects excluded external links via legacy exclude list' do
      ext_config = @config['external_links']
      expect(Jekyll::LinkAttributes.excluded?(ext_config: ext_config, section: 'rel', url: 'https://exclude.example.com')).to be true
      expect(Jekyll::LinkAttributes.excluded?(ext_config: ext_config, section: 'rel', url: 'https://exclude.example.com/nope')).to be false
      expect(Jekyll::LinkAttributes.excluded?(ext_config: ext_config, section: 'rel', url: 'https://include.example.com')).to be false
      expect(Jekyll::LinkAttributes.excluded?(ext_config: ext_config, section: 'rel', url: 'https://regex.example.com/excluded')).to be true
      expect(Jekyll::LinkAttributes.excluded?(ext_config: ext_config, section: 'rel', url: 'https://regex.example.com')).to be false
    end

    it 'falls back to legacy exclude list for target section too' do
      ext_config = @config['external_links']
      expect(Jekyll::LinkAttributes.excluded?(ext_config: ext_config, section: 'target', url: 'https://exclude.example.com')).to be true
    end

    it 'detects external links enabled' do
      expect(Jekyll::LinkAttributes.external_links_enabled?(config: @config)).to be true
      @config['external_links']['enabled'] = false
      expect(Jekyll::LinkAttributes.external_links_enabled?(config: @config)).to be false
    end

    it 'resolves rel from legacy string config' do
      ext_config = @config['external_links']
      expect(Jekyll::LinkAttributes.resolve_value(ext_config: ext_config, section: 'rel', legacy_key: 'rel',
                                                   default: 'fallback')).to eq('external nofollow noopener')
    end

    it 'resolves target from legacy string config' do
      ext_config = @config['external_links']
      expect(Jekyll::LinkAttributes.resolve_value(ext_config: ext_config, section: 'target', legacy_key: 'target',
                                                   default: 'fallback')).to eq('_blank')
    end

    it 'applies rel and target to external links via post_render_html' do
      html = '<html><body><a href="https://external.example.com">Link</a></body></html>'
      article = make_article(output: html)
      Jekyll::LinkAttributes.post_render_html(article)
      expect(article.output).to include('rel="external nofollow noopener"')
      expect(article.output).to include('target="_blank"')
    end

    it 'does not modify excluded links' do
      html = '<html><body><a href="https://exclude.example.com">Link</a></body></html>'
      article = make_article(output: html)
      Jekyll::LinkAttributes.post_render_html(article)
      expect(article.output).not_to include('rel=')
      expect(article.output).not_to include('target=')
    end

    it 'does not modify links that already have rel or target' do
      html = '<html><body><a href="https://external.example.com" rel="noopener" target="_self">Link</a></body></html>'
      article = make_article(output: html)
      Jekyll::LinkAttributes.post_render_html(article)
      expect(article.output).to include('rel="noopener"')
      expect(article.output).to include('target="_self"')
    end
  end

  # ── New-style config (v2) ────────────────────────────────

  describe 'new-style section configuration' do
    before :each do
      @config = {
        'url' => 'https://config.example.com',
        'external_links' => {
          'enabled' => true,
          'rel' => {
            'value' => 'nofollow noopener',
            'exclude' => %w[https://rel-ok.example.com]
          },
          'target' => {
            'value' => '_blank',
            'exclude' => %w[https://target-ok.example.com]
          }
        }
      }
    end

    it 'resolves rel value from section config' do
      ext_config = @config['external_links']
      expect(Jekyll::LinkAttributes.resolve_value(ext_config: ext_config, section: 'rel', legacy_key: 'rel',
                                                   default: 'fallback')).to eq('nofollow noopener')
    end

    it 'resolves target value from section config' do
      ext_config = @config['external_links']
      expect(Jekyll::LinkAttributes.resolve_value(ext_config: ext_config, section: 'target', legacy_key: 'target',
                                                   default: 'fallback')).to eq('_blank')
    end

    it 'falls back to default if section hash has no value key' do
      @config['external_links']['rel'] = { 'exclude' => [] }
      ext_config = @config['external_links']
      expect(Jekyll::LinkAttributes.resolve_value(ext_config: ext_config, section: 'rel', legacy_key: 'rel',
                                                   default: 'the-default')).to eq('the-default')
    end

    it 'uses section-specific exclude for rel' do
      ext_config = @config['external_links']
      expect(Jekyll::LinkAttributes.excluded?(ext_config: ext_config, section: 'rel', url: 'https://rel-ok.example.com')).to be true
      expect(Jekyll::LinkAttributes.excluded?(ext_config: ext_config, section: 'rel', url: 'https://target-ok.example.com')).to be false
    end

    it 'uses section-specific exclude for target' do
      ext_config = @config['external_links']
      expect(Jekyll::LinkAttributes.excluded?(ext_config: ext_config, section: 'target', url: 'https://target-ok.example.com')).to be true
      expect(Jekyll::LinkAttributes.excluded?(ext_config: ext_config, section: 'target', url: 'https://rel-ok.example.com')).to be false
    end

    it 'applies independent excludes via post_render_html' do
      html = '<html><body><a href="https://rel-ok.example.com">Link</a></body></html>'
      article = make_article(output: html)
      Jekyll::LinkAttributes.post_render_html(article)
      # rel-ok is excluded from rel but not target
      expect(article.output).not_to include('rel=')
      expect(article.output).to include('target="_blank"')
    end
  end

  # ── UTM parameters ──────────────────────────────────────

  describe 'UTM parameters' do
    before :each do
      @config = {
        'url' => 'https://mysite.com',
        'external_links' => {
          'enabled' => true,
          'rel' => { 'value' => 'noopener', 'exclude' => [] },
          'target' => { 'value' => '_blank', 'exclude' => [] },
          'utm' => {
            'enabled' => true,
            'source' => 'mysite.com',
            'medium' => 'website'
          }
        }
      }
    end

    it 'returns nil when utm is disabled' do
      ext_config = { 'utm' => { 'enabled' => false } }
      article = make_article(output: '')
      expect(Jekyll::LinkAttributes.build_utm_params(ext_config: ext_config, site_config: @config, article: article)).to be_nil
    end

    it 'returns nil when utm section is absent' do
      article = make_article(output: '')
      expect(Jekyll::LinkAttributes.build_utm_params(ext_config: {}, site_config: @config, article: article)).to be_nil
    end

    it 'builds utm params with configured source and medium' do
      ext_config = @config['external_links']
      article = make_article(output: '', url: '/')
      params = Jekyll::LinkAttributes.build_utm_params(ext_config: ext_config, site_config: @config, article: article)
      expect(params['utm_source']).to eq('mysite.com')
      expect(params['utm_medium']).to eq('website')
    end

    it 'derives campaign as homepage for root page' do
      ext_config = @config['external_links']
      article = make_article(output: '', layout: 'default', url: '/')
      params = Jekyll::LinkAttributes.build_utm_params(ext_config: ext_config, site_config: @config, article: article)
      expect(params['utm_campaign']).to eq('homepage')
    end

    it 'derives campaign as blog for post layout' do
      ext_config = @config['external_links']
      article = make_article(output: '', layout: 'post', url: '/blog/my-post/')
      params = Jekyll::LinkAttributes.build_utm_params(ext_config: ext_config, site_config: @config, article: article)
      expect(params['utm_campaign']).to eq('blog')
    end

    it 'derives campaign from first path segment for other layouts' do
      ext_config = @config['external_links']
      article = make_article(output: '', layout: 'default', url: '/about/')
      params = Jekyll::LinkAttributes.build_utm_params(ext_config: ext_config, site_config: @config, article: article)
      expect(params['utm_campaign']).to eq('about')
    end

    it 'derives content from slug when available' do
      ext_config = @config['external_links']
      article = make_article(output: '', slug: 'my-great-post', url: '/blog/my-great-post/')
      params = Jekyll::LinkAttributes.build_utm_params(ext_config: ext_config, site_config: @config, article: article)
      expect(params['utm_content']).to eq('my-great-post')
    end

    it 'derives content from url basename when slug is absent' do
      ext_config = @config['external_links']
      article = make_article(output: '', url: '/about/')
      params = Jekyll::LinkAttributes.build_utm_params(ext_config: ext_config, site_config: @config, article: article)
      expect(params['utm_content']).to eq('about')
    end

    it 'uses index as content for root page' do
      ext_config = @config['external_links']
      article = make_article(output: '', url: '/')
      params = Jekyll::LinkAttributes.build_utm_params(ext_config: ext_config, site_config: @config, article: article)
      expect(params['utm_content']).to eq('index')
    end

    it 'falls back to site url for source when not configured' do
      @config['external_links']['utm'].delete('source')
      ext_config = @config['external_links']
      article = make_article(output: '', url: '/')
      params = Jekyll::LinkAttributes.build_utm_params(ext_config: ext_config, site_config: @config, article: article)
      expect(params['utm_source']).to eq('mysite.com')
    end

    it 'appends utm params to external links' do
      params = { 'utm_source' => 'test', 'utm_medium' => 'web' }
      result = Jekyll::LinkAttributes.append_utm_params(url: 'https://example.com/page', utm_params: params)
      expect(result).to eq('https://example.com/page?utm_source=test&utm_medium=web')
    end

    it 'preserves existing query params' do
      params = { 'utm_source' => 'test' }
      result = Jekyll::LinkAttributes.append_utm_params(url: 'https://example.com/page?foo=bar', utm_params: params)
      expect(result).to include('foo=bar')
      expect(result).to include('utm_source=test')
    end

    it 'does not overwrite existing utm params on a link' do
      params = { 'utm_source' => 'plugin', 'utm_medium' => 'web' }
      result = Jekyll::LinkAttributes.append_utm_params(url: 'https://example.com?utm_source=original', utm_params: params)
      expect(result).to include('utm_source=original')
      expect(result).to include('utm_medium=web')
    end

    it 'returns original url for invalid URIs' do
      params = { 'utm_source' => 'test' }
      bad_url = 'https://exam ple.com'
      expect(Jekyll::LinkAttributes.append_utm_params(url: bad_url, utm_params: params)).to eq(bad_url)
    end

    it 'appends utm params via post_render_html' do
      html = '<html><body><a href="https://external.example.com">Link</a></body></html>'
      article = make_article(output: html, url: '/')
      Jekyll::LinkAttributes.post_render_html(article)
      expect(article.output).to include('utm_source=mysite.com')
      expect(article.output).to include('utm_medium=website')
      expect(article.output).to include('utm_campaign=homepage')
      expect(article.output).to include('utm_content=index')
    end

    it 'does not add utm to internal links' do
      html = '<html><body><a href="/about">About</a></body></html>'
      article = make_article(output: html, url: '/')
      Jekyll::LinkAttributes.post_render_html(article)
      expect(article.output).not_to include('utm_source')
    end
  end

  # ── UTM excludes ─────────────────────────────────────────

  describe 'UTM excludes' do
    before :each do
      @config = {
        'url' => 'https://mysite.com',
        'external_links' => {
          'enabled' => true,
          'rel' => {
            'value' => 'noopener',
            'exclude' => %w[https://myapp.example.com(/?|/.*)?]
          },
          'target' => {
            'value' => '_blank',
            'exclude' => %w[https://myapp.example.com(/?|/.*)?]
          },
          'utm' => {
            'enabled' => true,
            'source' => 'mysite.com',
            'medium' => 'website',
            'exclude' => %w[https://github.com(/?|/.*)?]
          }
        }
      }
    end

    it 'does not add utm to excluded utm domains' do
      html = '<html><body><a href="https://github.com/org/repo">Repo</a></body></html>'
      article = make_article(output: html, url: '/')
      Jekyll::LinkAttributes.post_render_html(article)
      expect(article.output).not_to include('utm_source')
      # but rel/target should still be added
      expect(article.output).to include('rel="noopener"')
      expect(article.output).to include('target="_blank"')
    end

    it 'adds utm to links excluded from rel/target' do
      html = '<html><body><a href="https://myapp.example.com/dashboard">App</a></body></html>'
      article = make_article(output: html, url: '/')
      Jekyll::LinkAttributes.post_render_html(article)
      expect(article.output).to include('utm_source=mysite.com')
      expect(article.output).not_to include('rel=')
      expect(article.output).not_to include('target=')
    end

    it 'utm exclude defaults to empty when section has no exclude key' do
      @config['external_links']['utm'].delete('exclude')
      ext_config = @config['external_links']
      expect(Jekyll::LinkAttributes.excluded?(ext_config: ext_config, section: 'utm', url: 'https://anything.com')).to be false
    end

    it 'utm does not fall back to legacy exclude list' do
      @config['external_links'] = {
        'enabled' => true,
        'exclude' => %w[https://legacy-excluded.example.com],
        'utm' => { 'enabled' => true, 'source' => 'test', 'medium' => 'web' }
      }
      ext_config = @config['external_links']
      expect(Jekyll::LinkAttributes.excluded?(ext_config: ext_config, section: 'utm', url: 'https://legacy-excluded.example.com')).to be false
    end
  end

  # ── Exclude checks use original href ────────────────────

  describe 'exclude checks use original href' do
    before :each do
      @config = {
        'url' => 'https://mysite.com',
        'external_links' => {
          'enabled' => true,
          'rel' => {
            'value' => 'noopener',
            'exclude' => %w[https://myapp.example.com(/?|/.*)?]
          },
          'target' => {
            'value' => '_blank',
            'exclude' => %w[https://myapp.example.com(/?|/.*)?]
          },
          'utm' => {
            'enabled' => true,
            'source' => 'mysite.com',
            'medium' => 'website'
          }
        }
      }
    end

    it 'excludes rel/target based on original href, not utm-modified href' do
      html = '<html><body><a href="https://myapp.example.com/login">Login</a></body></html>'
      article = make_article(output: html, url: '/')
      Jekyll::LinkAttributes.post_render_html(article)
      # UTM should be added (not in utm excludes)
      expect(article.output).to include('utm_source=mysite.com')
      # rel/target should NOT be added (excluded for rel/target)
      expect(article.output).not_to include('rel=')
      expect(article.output).not_to include('target=')
    end
  end
end
