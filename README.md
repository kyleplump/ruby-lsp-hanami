# Ruby LSP Hanami Addon

A Ruby LSP addon for the [Hanami](https://hanamirb.org/) framework.

## Requirements
[Ruby LSP](https://github.com/Shopify/ruby-lsp) must be installed.

## Installation

### Note
:exclamation:  This project is still in active development, and as such, the gem does not yet exist.  If installing, please build from source :exclamation:


Install the Gem:
```
gem install ruby-lsp-hanami
```

or

```
bundle add ruby-lsp-hanami --group development
```

### VS Code

To enable auto-complete suggestions per keystroke in VS Code, as well as enabling Hanami specific diagnostics, update your `settings.json` with the following values:

```
{
  "editor.quickSuggestions": {
    "other": true,
    "comments": false,
    "strings": true
  },
  "editor.suggestOnTriggerCharacters": true,
  "rubyLsp.formatter": "hanami_diagnostics"
}
```


### Zed
Zed uses `solargraph` by default, update your settings to use `ruby-lsp`:
```
"languages": {
  "Ruby": {
    "language_servers": ["ruby-lsp"]
  }
},
"lsp": {
  "ruby-lsp": {
    "initialization_options": {
      "formatter": "hanami_diagnostics",
    }
  }
}
  ```

You can read more about configuring Ruby LSP support for Zed [here.](https://zed.dev/docs/languages/ruby#setting-up-ruby-lsp)

## Features

TODO

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/ruby_lsp_hanami.
