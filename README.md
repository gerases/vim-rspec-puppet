[![Build Status](https://travis-ci.com/gerases/vim-rspec-puppet.svg?branch=master)](https://travis-ci.com/gerases/vim-rspec-puppet)

# vim-rspec-puppet
A vim plugin for working with rspec-puppet. It's not a plugin for working with rspec more generally because it focuses specifically on puppet code, whose file structure is unique enough to warrant special treatment. The plugin also takes advantages of the terminal integration in Vim 8 by running the tests in a terminal tab.

The plugin handles two basic cases:

* If you're in a spec file, and invoke `Run_Spec()`, it will run the spec file.
* If you're in a puppet manifest (this is the special case making the puppet situation more unique):
  * it will try to extract the class name and find the closest spec file testing that class.
  * it will (failing to find the spec by the class name) offer to grep through the closest spec directory.

# Install
Install using [vim-plug](https://github.com/junegunn/vim-plug) or another vim plugin system. If you don't have a plugin system, put the file in a location that is sourced by Vim such as `~/.vim/plugin`.

# Use
Create a binding of your choice. For example:
```
nnoremap <leader>rs :call Run_Spec()<CR>
```

You can press that key combination in either a puppet or spec file. In addition,
you can define another binding to run rspec tests only against a specific line
in the spec file. This can be done like so:

```
nnoremap <leader>rl :call Run_Spec_Line()<CR>
```

# Dependencies
* [vim-spec](https://github.com/kana/vim-vspec) (to run the tests)
* Git
* [Ripgrep](https://github.com/BurntSushi/ripgrep)
* Vim >= 8.1 (because of the "terminal" capability in vim >= 8.1)

# Acknowledgements
Some of the ideas for the functionality were taken from this project: [vim-rspec](https://github.com/thoughtbot/vim-rspec/blob/master/plugin/rspec.vim)
