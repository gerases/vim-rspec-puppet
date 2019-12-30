" ===============
" Local functions
" ===============
function! s:Set_Up()
endfunction

function! s:Cd_back()
  exec s:cd_back
endfunction

function! s:Run_Rspec_Cmd(location)
  " If a list of paths was passed, turn it into a space separated string
  if type(a:location) == 3
    let spec_paths = join(a:location, ' ')
  " Otherwise, assume it's a string containing a single location
  else
    let spec_paths = a:location
  endif

  if s:test_mode == 1
    let s:rspec_command = 'rspec -fd --fail-fast ' . spec_paths
    call s:Cd_back()
    return
  endif

  " Save the file
  exe "normal :w\<CR>"

  " Run the rspec tests
  exe "normal :-tab terminal rspec -fd --fail-fast " . spec_paths . "\<CR>"
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

function! s:Find_And_Run_Spec_File()
  " Cd to the directory of the file so we can search upward
  " :h removes the last component of the path
  cd %:h

  " Find the closest spec dir upward of the file until
  " the root of the repo
  let spec_dir = finddir('spec', ';' . s:repo_root . ';')
  if empty(spec_dir)
    echo "Couldn't find a spec dir"
    call s:Cd_back()
    return
  endif

  " Cd to the found spec dir's parent so that we're at the same level as the
  " spec dir
  exe 'cd ' . spec_dir . '/..'

  " Try to get the spec files that test this class.
  let class_name = s:Find_Spec_File_From_Puppet_Manifest()
  if empty(class_name)
    echoerr 'Could not determine the class name in ' . expand('%:p')
    call s:Run_Rspec_Cmd('spec')
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
    echoerr "Can't find the 'rg' binary in the binary paths"
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

  let specs = system("rg -lg '*_spec.rb' " . class_name . ' ' . spec_dir)
  " Grep for the class name under the spec dir
  if empty(specs)
    echoerr 'Could not find mention of class ' . class_name . ' under ' . spec_dir
  else
    " In almost all cases the class we're testing should only have one
    " file, but if there are several, Run_Rspec_Cmd will call them all.
    call s:Run_Rspec_Cmd(split(specs, "\n"))
  endif

  call s:Cd_back()
endfunction

" =================
" Global functions
" =================
function! Run_Spec(test_mode)
  let s:old_path = getcwd()
  let s:cd_back  = 'cd ' . s:old_path
  let s:test_mode = a:test_mode

  let s:repo_root = system('git rev-parse --show-toplevel')
  if empty(s:repo_root)
    echo "Couldn't find the repo root. It's not a git repo?"
    return
  endif

  if matchstr(expand('%:p'), '[.]pp$') != ""
    " It's a puppet manifest. Try to find the the spec(s) for it
    call s:Find_And_Run_Spec_File()
  elseif matchstr(expand('%:p'), '_spec.rb$') != ""
    " We have a real spec file. To be pedantic, we shouldn't cd all the way to
    " the repo root, but just to the directory directly above the spec
    " directory of this file, but it's quicker to cd to the repo root and use
    " the absolute path to the spec file.
    exe 'cd ' . s:repo_root
    call s:Run_Rspec_Cmd(expand('%:p'))
  else
    echom "Not a puppet or rspec file"
    return
  endif
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
