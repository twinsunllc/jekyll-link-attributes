# Jekyll Link Attributes

This plugin adds `rel` and `target` attributes to all external links in your Jekyll site.
The default configuration opens external links in a new tab and conserves domain authority for your site.

## Setup

1. Add the gem to your `Gemfile`:
    ```ruby
    gem 'jekyll-link-attributes'
    ```
2. Run `bundle install` to install the gem
3. Add the following to your `_config.yml`:
    ```yaml
    plugins:
      - jekyll-link-attributes
    ```

## Usage

### Configuration

You can override the default configuration by adding the following section to your Jekyll site's `_config.yml`:

```yaml
external_links:
  enabled: true
  rel: external nofollow noopener
  target: _blank
  exclude:
    - https://example.com
    - https://another.example.com/test.html
    - https://regex.example.com/.+
```

#### Default Configuration
| Key | Default Value | Description |
| ---------------------------- | ---------------------------- | -------------------------------------------------- |
| `external_links.enabled` | `true`                       | Enable attribute modifications for external links. |
| `external_links.rel`     | `external nofollow noopener` | The `rel` attribute to add to external links.      |
| `external_links.target`  | `_blank`                     | The `target` attribute to add to external links.   |
| `external_links.exclude` | `[]`                         | A list of URLs to exclude from processing.         |


### Skipping individual links

The `rel` or `target` attributes will not be modified for links that already have those existing attributes.
This allows you to skip individual links without having to modify the plugin's configuration.

 ```html
 <a href"https://example.com" rel="nofollow">Example</a> <!-- `rel` will not be modified, but the configured `target` will be added. -->
 <a href"https://example.com" target="_self">Example</a> <!-- `target` will not be modified, but the configured `rel` will be added. -->
 <a href"https://example.com" rel="nofollow" target="_self">Example</a> <!-- Neither `rel` nor `target` will be modified. -->
 ```

## Contributing

Pull requests are welcome!
If you wish to change existing behavior, please open an issue to discuss the change before investing time in a PR.
RSpec tests are encouraged for any new features.

## Supported by Twin Sun

This project is maintained by [Twin Sun](https://twinsunsolutions.com/), a custom mobile and web app development agency in Nashville, TN.
