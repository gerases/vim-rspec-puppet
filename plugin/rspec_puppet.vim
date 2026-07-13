" ===============
" Local functions
" ===============

" Finds the tab/window containing the last rspec command and closes it
function! s:FindAndCloseLastTerminalWindow()
  let i = 1
  let l:current_tab = tabpagenr()
  while i <= tabpagenr('$')
    exe 'normal ' . i . 'gt'
    let buflist = tabpagebuflist(i)
    for bufnr in buflist
      " Before closing the tab with the terminal window, we check that:
      " * The buffer loaded into the window is of type 'terminal'
      " * The job has finished (modifiable=0)
      " * The command starts with '!rspec'
      if getbufvar(bufnr, '&buftype') == 'terminal'
        \ && term_getstatus(bufnr) ==# 'finished'
        \ && match(bufname(bufnr), '^!rspec') != -1
        let l:winnr = bufwinnr(bufnr)
        exe ':' . l:winnr . 'close'
      endif
    endfor
    let i = i + 1
  endwhile

  " Return to the remembered tab
  exe 'normal ' . l:current_tab . 'gt'
endfunction

function! s:Find_Module_Root()
  let l:dir = expand('%:p:h')
  let l:git_root = systemlist('git -C ' . shellescape(l:dir) . ' rev-parse --show-toplevel')
  let l:stop_at = v:shell_error == 0 ? l:git_root[0] : expand('~')

  while 1
    if isdirectory(l:dir . '/spec')
      return l:dir
    endif
    let l:parent = fnamemodify(l:dir, ':h')
    if l:dir ==# l:stop_at || l:parent ==# l:dir
      break
    endif
    let l:dir = l:parent
  endwhile

  return ''
endfunction

function! s:Run_Rspec_Cmd(location, module_root)
  call s:FindAndCloseLastTerminalWindow()

  " If a list of paths was passed, turn it into a space separated string
  if type(a:location) == 3
    let l:spec_paths = join(a:location, ' ')
  " Otherwise, assume it's a string containing a single location
  else
    let l:spec_paths = a:location
  endif

  if exists("s:test_mode")
    let s:rspec_command = 'rspec -fd --fail-fast ' . l:spec_paths
    return
  endif

  exe "silent! normal :w\<CR>"

  if has('nvim') == 0 && has('terminal') == 0
    echo "No terminal support in this version of vim. Aborting"
    return
  endif

  let l:cmdheight_val = &cmdheight
  set cmdheight=2
  silent! exe '-tabnew'
  call term_start('rspec -fd --fail-fast ' . l:spec_paths, {'curwin': 1, 'cwd': a:module_root})

  let l:current_tab = tabpagenr()
  exe 'normal ' . (l:current_tab + 1) . 'gt'
  set cmdheight=1
  exe 'normal ' . l:current_tab . 'gt'
  exe 'set cmdheight=' . l:cmdheight_val
endfunction

" Returns names of one or more files that test ('describe' in rspec speak) a
" puppet class.
function! s:Find_Spec_File_From_Puppet_Manifest()
  " Search for the word 'class' wrapping the search if necessary and not
  " moving the cursor.
  let line_no = search('^class\|^define', 'wn')
  if line_no == 0
    return
  endif

  let line_contents = getline(line_no)

  " Extract the name of the class
  let class_name = matchstr(line_contents, '^\(class\|define\) \zs[a-zA-Z0-9_:]\+\ze')
  if class_name == ''
    return
  endif

  return class_name
endfunction

" Returns the manifest path (relative to the module root) for a spec file
" by parsing the describe line to extract the fully-qualified class name.
function! s:Find_Manifest_From_Spec()
  let line_no = search('^describe', 'wn')
  if line_no == 0
    return ''
  endif

  let line_contents = getline(line_no)
  let class_name = matchstr(line_contents, '^describe\s*[''"]\zs[^''"]\+\ze')
  if class_name == ''
    return ''
  endif

  let parts = split(class_name, '::')
  if len(parts) == 1
    return 'manifests/init.pp'
  else
    return 'manifests/' . join(parts[1:], '/') . '.pp'
  endif
endfunction

function! s:Find_Spec_File(module_root)
  let class_name = s:Find_Spec_File_From_Puppet_Manifest()
  if empty(class_name)
    echo 'Could not determine the class name in ' . expand('%:p')
    return ''
  end

  let class_name_pieces = split(class_name, '::')
  let l:variants = [
      \ ['spec', 'classes', class_name],
      \ ['spec', 'classes', join(class_name_pieces, '/')],
      \ ['spec', 'classes', join(class_name_pieces[1:-1], '/')],
      \ ['spec', 'defines', join(class_name_pieces[1:-1], '/')],
      \ ]

  if expand('%:t') == 'init.pp'
    call add(l:variants, ['spec', 'classes', 'init'])
  endif

  for variant in l:variants
    let l:rel_path = join(variant, '/') . '_spec.rb'
    let l:abs_path = a:module_root . '/' . l:rel_path
    if filereadable(l:abs_path)
      return l:abs_path
    endif
  endfor

  let rg_exists = system('which rg')
  if v:shell_error != 0
    echo "Can't find the 'rg' binary in the binary paths"
    return ''
  endif

  let l:rg_search = system('rg -l --color=never -- "^describe.*' . class_name . '[^:]" ' . shellescape(a:module_root))
  let l:specs = split(l:rg_search, "\n")
  if len(l:specs) == 0
    echo "Nothing found"
    return ''
  endif

  if len(l:specs) == 1
    return l:specs[0]
  endif

  let options = {
      \ 'options': ['--prompt', 'Spec> ', '--preview', 'cat {}'],
      \ 'source': l:specs,
      \ 'window' : { 'height': '20%', 'width': '100%' },
      \ 'sink': 'tabedit',
      \ }
  call fzf#run(fzf#wrap(options))
  return ''
endfunction

function! s:Run_Spec_File(module_root)
  let l:spec = s:Find_Spec_File(a:module_root)
  if !empty(l:spec)
    call s:Run_Rspec_Cmd(l:spec, a:module_root)
  endif
endfunction

function! s:Get_Buf_Type()
  if &buftype != ''
    return 0
  endif

  if matchstr(expand('%:p'), '[.]pp$') != ""
    return 1
  endif

  if matchstr(expand('%:p'), '_spec.rb$') != ""
    return 2
  endif

  return 0
endfunction

function! s:turn_on_test_mode()
  let s:test_mode = 1
endfunction

" =================
" Global functions
" =================
function! Open_Spec_File()
  if matchstr(expand('%:p'), '[.]pp$') == ""
    echo "Not a puppet file"
    return
  endif

  let l:module_root = s:Find_Module_Root()
  if empty(l:module_root)
    echo "Couldn't find a spec dir"
    return
  endif

  let l:spec = s:Find_Spec_File(l:module_root)
  if empty(l:spec)
    return
  endif
  execute 'tabedit' l:spec
endfunction

function! Open_Manifest_File()
  if matchstr(expand('%:p'), '_spec.rb$') == ""
    echo "Not a spec file"
    return
  endif

  let l:module_root = s:Find_Module_Root()
  if empty(l:module_root)
    echo "Couldn't find a spec dir"
    return
  endif

  let l:manifest_path = s:Find_Manifest_From_Spec()
  if empty(l:manifest_path)
    echo "Could not determine the manifest path from the spec file"
    return
  endif

  let l:abs_path = l:module_root . '/' . l:manifest_path
  if !filereadable(l:abs_path)
    echo "Manifest not found: " . l:abs_path
    return
  endif

  execute 'tabedit' l:abs_path
endfunction

function! Run_Spec(...)
  let l:buffer_type = s:Get_Buf_Type()
  if l:buffer_type == 0
    echo "Not a puppet or rspec file"
    return
  endif

  let l:module_root = s:Find_Module_Root()
  if empty(l:module_root)
    echo "Couldn't find a spec dir"
    return
  endif

  if l:buffer_type == 1
    call s:Run_Spec_File(l:module_root)
  else
    let l:location = expand('%:p')
    if a:0 > 0
      let l:location = l:location . ':' . a:1
    endif
    call s:Run_Rspec_Cmd(l:location, l:module_root)
  endif
  exe "set cmdheight=1"
  redraw!
endfunction

function! Run_Spec_Line()
  call Run_Spec(line('.'))
endfunction

" begin vspec config
function! rspec_puppet#scope()
  return s:
endfunction

function! rspec_puppet#sid()
    return maparg('<SID>', 'n')
endfunction
nnoremap <SID> <SID>
" end vspec config
