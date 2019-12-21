# vim-rspec-puppet
A vim plugin for working with rspec-puppet

This is an attempt to facilitate running rspec-puppet tests from Vim. It handles
two basic cases:

* If you're in a spec file, and invoke `Run_Spec()`, it will run the spec file.
* If you're in a puppet manifest:
  * it will try to find the closest spec file upward of the file and run it.
  * failing find the spec file, it will offer to grep through the closest sepc
    directory in an attempt to find the spec file that tests the puppet file
    one is in.

# Install
<to be documented>
Install using https://github.com/junegunn/vim-plug or something similar.

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
