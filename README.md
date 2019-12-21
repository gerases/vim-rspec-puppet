# vim-rspec-puppet
A vim plugin for working with rspec-puppet. It's not a plugin for working with rspec more generally because it focuses specifically on puppet code, whose file structure is unique enough to warrant special treatment.

The plugin handles two basic cases:

* If you're in a spec file, and invoke `Run_Spec()`, it will run the spec file.
* If you're in a puppet manifest (this is the special case making the puppet situation more unique):
  * it will try to extract the class name and find the closest spec file testing that class.
  * failing find the spec file, it will offer to grep through the closest spec directory.

# Install
<to be documented>
Install using https://github.com/junegunn/vim-plug or another vim plugin system. If you don't have a plugin system (you really should), put the file in a location that is sourced by Vim such as `~/.vim/plugin`.
 
# Use
Create a binding of your choice. For example:
```
" Run rspec
nnoremap <leader>rs :call Run_Spec()<CR>
```

# Dependencies

* Git
* Ripgrep (https://github.com/BurntSushi/ripgrep)
* Vim >= 8.1
