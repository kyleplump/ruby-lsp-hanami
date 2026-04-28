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

### :wrench: Optional Editor Configuration
Currently, **VS Code** offers the most feature complete experience, and is the our primary development target.  There are plans to bring other editors to feature parity, and this README will be updated accordingly.

#### VS Code :green_circle:

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


#### Zed :yellow_circle:
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

- 'Go-to-definition' support for `Deps` dependencies.
- Autocompletion of `Deps` dependencies. 
- 'Key not found' diagnostics for `Deps` dependencies.
- 'CodeLens' capabilities ('Jump to [Template|View|Route]' from within your `Hanami::Action`). 

## Contributing

1. Fork it (https://github.com/hanami/ruby-lsp-hanami/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

In addition to contributing code, you can help to triage issues. This can include reproducing bug reports, or asking for vital information such as version numbers or reproduction instructions. If you would like to start triaging issues, one easy way to get started is to [subscribe to hanami on CodeTriage](https://www.codetriage.com/hanami/hanami).
