[![Build Status](https://travis-ci.com/gerases/vim-rspec-puppet.svg?branch=master)](https://travis-ci.com/gerases/vim-rspec-puppet)

# vim-rspec-puppet
A vim plugin for working with rspec-puppet. It grew out of this great mapping suggested by [TheLocehiliosan](https://github.com/TheLocehiliosan):

```
nnoremap rs :w:-tab terminal rspec -fd %
```

It's not a plugin for working with rspec more generally because it focuses specifically on puppet code, whose file structure is unique enough to warrant special treatment. It's espcially useful for situations where one is maintaining a puppet code base with multiple component modules, profiles and roles. The plugin facilitates navigating the puppet code and running rspec tests without ever having to leave Vim. As opposed to other rspec plugins, the rspec commands are run in a tab, which was made possible by the terminal integration in Vim 8.

The plugin handles two basic cases:

* If you're in a spec file, and invoke `Run_Spec()`, it will run the spec file.
* If you're in a spec file, and invoke `Run_Spec_Line()`, rspec will run against the line the cursor is on.
* If you're in a puppet manifest (this is the special case making the puppet situation more unique):
  * it will try to extract the class name and find the closest spec file testing that class.
  * it will (failing to find the spec by the class name) offer to grep through the closest spec directory.
  
This is my first Vim plugin, so there could very well be things done contrary to the best Vim coding practices. If you notice something, I'll be glad to adjust the code accordingly. Really, all this code should be somehow integrated in the [existing](https://github.com/thoughtbot/vim-rspec) vim-rspec plugin, but I needed this fast for my needs. Maybe some time later I'll put together a PR into that project.

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
Some of the ideas for the functionality were taken from this project: [vim-rspec](https://github.com/thoughtbot/vim-rspec), especially the testing setup.
