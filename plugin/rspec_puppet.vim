" ===============
" Local functions
" ===============
function! s:Cd_back()
  exec s:cd_back
endfunction

function! s:Run_Rspec_Cmd(location)
  " If a list of paths was passed, turn it into a space separated string
  if type(a:location) == 3
    let l:spec_paths = join(a:location, ' ')
  " Otherwise, assume it's a string containing a single location
  else
    let l:spec_paths = a:location
  endif

  if exists("s:test_mode")
    let s:rspec_command = 'rspec -fd --fail-fast ' . l:spec_paths
    call s:Cd_back()
    return
  endif

  " Save the file
  exe "normal :w\<CR>"

  if has('terminal') == 0
    echo "No terminal support in this version of vim. Aborting"
    return
  endif

  " Run the rspec tests
  exe "normal :-tab terminal rspec -fd --fail-fast " . l:spec_paths . "\<CR>"
  call s:Cd_back()
endfunction

" Returns names of one or more files that test ('describe' in rspec speak) a
" puppet class.
function! s:Find_Spec_File_From_Puppet_Manifest()
  " Search for the word 'class' wrapping the search if necessary and not
  " moving the cursor.
  let line_no = search('^class', 'wn')
  if line_no == 0
    return
  endif

  let line_contents = getline(line_no)

  " Extract the name of the class
  let class_name = matchstr(line_contents, 'class \zs[a-zA-Z0-9_:]\+\ze')
  if class_name == ''
    return
  endif

  return class_name
endfunction

function! s:Find_Nearest_Spec_Dir()
  " Cd to the directory of the file so we can search upward
  " :h removes the last component of the path
  cd %:h

  " Holds the path to a directory beyond which the search should not continue
  let l:stop_search_at = ""

  call system('which git')
  if v:shell_error == 0
    let l:stop_search_at = system('git rev-parse --show-toplevel')
  endif

  " If we don't have a repo root, default to home dir
  if l:stop_search_at == ""
    let l:stop_search_at = '~'
  endif

  " Find the closest spec dir upward of the file until
  " the directory in stop_search_at.
  let spec_dir = finddir('spec', ';' . l:stop_search_at)
  if empty(spec_dir)
    echo "Couldn't find a spec dir"
    call s:Cd_back()
    return
  endif

  " Cd to the found spec dir's parent so that we're at the same level as the
  " spec dir
  exe 'cd ' . spec_dir . '/..'
  return 1
endfunction

function! s:Find_And_Run_Spec_File()
  if s:Find_Nearest_Spec_Dir() != 1
    return
  endif

  " Try to get the spec files that test this class.
  let class_name = s:Find_Spec_File_From_Puppet_Manifest()
  if empty(class_name)
    echo 'Could not determine the class name in ' . expand('%:p')
    call s:Cd_back()
    return
  end

  let class_name_pieces = split(class_name, '::')
  " Construct the expected spec file path which could be:
  " spec/classes/<CLASS_NAME>_spec.rb
  let spec_path_base_1 = ['spec', 'classes', class_name]
  " spec/classes/<ALL_CLASS_NAME_PIECES>_spec.rb
  let spec_path_base_2 = ['spec', 'classes', join(class_name_pieces, '/')]
  " spec/classes/<ALL_CLASS_NAME_PIECES_EXCEPT_FIRST>_spec.rb
  let spec_path_base_3 = ['spec', 'classes', join(class_name_pieces[1:-1], '/')]

  for variant in [ spec_path_base_1, spec_path_base_2, spec_path_base_3 ]
    let full_path = join(variant, '/') . '_spec.rb'
    if filereadable(full_path)
      call s:Run_Rspec_Cmd(full_path)
      return
    endif
  endfor

  " If the above fails, we can try to grep with rg
  let rg_exists = system('which rg')
  if v:shell_error != 0
    echo "Can't find the 'rg' binary in the binary paths"
    call s:Cd_back()
    return
  endif

  call inputsave()
  let yes = (input('Could not find spec file. Grep spec dir? (y/N) ') =~? '^y')
  call inputrestore()
  if !yes
    call s:Cd_back()
    return
  endif

  " Echo newline or next message (if any) will continue on the prompt line
  " above
  echo "\n"

  let specs = system("rg -lg '*_spec.rb' " . class_name . ' ' . spec_dir)
  " Grep for the class name under the spec dir
  if empty(specs)
    echo 'Could not find mention of class ' . class_name . ' under ' . spec_dir
  else
    " In almost all cases the class we're testing should only have one
    " file, but if there are several, Run_Rspec_Cmd will call them all.
    call s:Run_Rspec_Cmd(split(specs, "\n"))
  endif

  call s:Cd_back()
endfunction

function! s:turn_on_test_mode()
  let s:test_mode = 1
endfunction

" =================
" Global functions
" =================
function! Run_Spec(...)
  let s:old_path = getcwd()
  let s:cd_back  = 'cd ' . s:old_path

  let l:is_puppet_manifest = 0
  if matchstr(expand('%:p'), '[.]pp$') != ""
    let l:is_puppet_manifest = 1
  elseif matchstr(expand('%:p'), '_spec.rb$') == ""
    echo "Not a puppet or rspec file"
    return
  endif

  " Find the nearest spec dir and cd to its parent.
  " This needs to be done for both puppet manifests
  " and spec files.
  if s:Find_Nearest_Spec_Dir() != 1
    return
  endif

  if l:is_puppet_manifest == 1
    " It's a puppet manifest - try to find the matching spec file.
    call s:Find_And_Run_Spec_File()
  else
    let l:location = expand('%:p')
    " We have a spec file - run it directly.
    if a:0 > 0
      " If we have a line number in the arguments, append it
      " to the spec file name. Rspec will then run tests
      " only for that line number.
      let l:location = l:location . ':' . a:1
    endif
    call s:Run_Rspec_Cmd(l:location)
  endif
endfunction

function! Run_Spec_Line()
  Run_Spec(line('.'))
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
