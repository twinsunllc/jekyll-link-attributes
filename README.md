# Jekyll Link Attributes

A Jekyll plugin for managing external link behavior: `rel` attributes, `target` attributes, and UTM tracking parameters.
Each concern is independently configurable with its own value and exclude list.

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

## Configuration

### Recommended (v2+)

Each attribute type is its own section with a `value` and optional `exclude` list:

```yaml
external_links:
  enabled: true

  rel:
    value: external nofollow noopener
    exclude:
      - https://myotherapp.com(/?|/.*)?

  target:
    value: _blank
    exclude:
      - https://myotherapp.com(/?|/.*)?

  utm:
    enabled: true
    source: mysite.com
    medium: website
    exclude:
      - https://github.com(/?|/.*)?
```

### Legacy (v1, still supported)

The original flat configuration style continues to work. The top-level `rel`, `target`, and `exclude` keys are used as fallbacks when the new-style section config is not present:

```yaml
external_links:
  enabled: true
  rel: external nofollow noopener
  target: _blank
  exclude:
    - https://example.com(/?|/.*)?
```

### Resolution order

| Setting | Resolved from | Fallback |
| ------- | ------------- | -------- |
| rel value | `external_links.rel.value` | `external_links.rel` (string) or `external nofollow noopener` |
| rel excludes | `external_links.rel.exclude` | `external_links.exclude` |
| target value | `external_links.target.value` | `external_links.target` (string) or `_blank` |
| target excludes | `external_links.target.exclude` | `external_links.exclude` |
| utm excludes | `external_links.utm.exclude` | *(none, defaults to empty)* |

### UTM tracking parameters

When `external_links.utm.enabled` is `true`, UTM query parameters are automatically appended to external links:

| Param | Value | Source |
| -------------- | -------------------- | ---------------------------------------------------------------- |
| `utm_source`   | Configured `source`  | Falls back to the site `url` with the protocol stripped.         |
| `utm_medium`   | Configured `medium`  | Falls back to `website`.                                         |
| `utm_campaign` | Auto-derived         | `blog` for post/blog layouts, otherwise the first URL path segment (e.g., `about`), or `homepage` for the root page. |
| `utm_content`  | Auto-derived         | The page slug (e.g., `my-great-post` or `index`).               |

Existing query parameters on links are preserved. UTM parameters already present on a link will not be overwritten.

### Skipping individual links

The `rel` or `target` attributes will not be modified for links that already have those existing attributes.
This allows you to skip individual links without having to modify the plugin's configuration.

 ```html
 <a href="https://example.com" rel="nofollow">Example</a> <!-- rel will not be modified, but target will be added. -->
 <a href="https://example.com" target="_self">Example</a> <!-- target will not be modified, but rel will be added. -->
 <a href="https://example.com" rel="nofollow" target="_self">Example</a> <!-- Neither rel nor target will be modified. -->
 ```

## Contributing

Pull requests are welcome!
If you wish to change existing behavior, please open an issue to discuss the change before investing time in a PR.
RSpec tests are encouraged for any new features.

## Supported by Twin Sun

This project is maintained by [Twin Sun](https://twinsunsolutions.com/), a custom mobile and web app development agency in Nashville, TN.
