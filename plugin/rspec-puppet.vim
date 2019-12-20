function! Run_Rspec_Cmd(location)
  " If a list of paths was passed, turn it into a space separated string
  if type(a:location) == 3
    let spec_paths = join(a:location, ' ')
  " Otherwise, assume it's a string containing a single location
  else
    let spec_paths = a:location
  endif

  " Save the file
  exe "normal :w\<CR>"

  " Run the rspec tests
  exe "normal :-tab terminal rspec -fd --fail-fast " . spec_paths . "\<CR>"
endfunction

" Returns one or more files that test this puppet class
function! Find_Spec_File_From_Puppet_Manifest()
  " Search for the word 'class' wrapping the search if necessary and not
  " moving the cursor.
  let line_no = search('^class', 'wn')
  if line_no == 0
    return
  endif

  let line_contents = getline(line_no)
  let class_name = matchstr(line_contents, 'class \zs[^ ]\+\ze')
  if class_name == ''
    return
  endif

  return class_name
endfunction

function! Find_And_Run_Spec_File()
  let old_path = getcwd()
  let cd_back = 'cd ' . old_path

  " Cd to the directory of the file so we can search upward
  " :h removes the last component of the path
  cd %:h

  let repo_root = system('git rev-parse --show-toplevel')
  if empty(repo_root)
    echo "Couldn't find the repo root. It's not a git repo?"
    return
  endif

  " Find the closest spec dir upward of the file until
  " the root of the repo
  let spec_dir = finddir('spec', ';' . repo_root . ';')
  if empty(spec_dir)
    echo "Couldn't find a spec dir"
    exe cd_back
    return
  endif

  " Cd to the found spec dir's parent so that we're at the same level as the
  " spec dir
  exe 'cd ' . spec_dir . '/..'

  " Try to get the spec files that test this class.
  let class_name = Find_Spec_File_From_Puppet_Manifest()
  if empty(class_name)
    echom 'Could not determine the class name in ' . expand('%:p')

    call Run_Rspec_Cmd('spec')
    exe cd_back
    return
  end

  let class_name_pieces = split(class_name, '::')
  " Construct the expected spec file path which should be:
  " spec/classes/<REST_OF_CLASS_NAME_PIECES>_spec.rb
  let spec_path_base = ['spec', 'classes', join(class_name_pieces[1:-1], '/')]
  let full_path = join(spec_path_base, '/') . '_spec.rb'
  if filereadable(full_path)
    call Run_Rspec_Cmd(full_path)
    exe cd_back
    return
  endif

  let rg_exists = system('which rg')
  if v:shell_error != 0
    echom "Can't find the 'rg' binary in the binary paths"
    exe cd_back
    return
  endif

  call inputsave()
  let yes = (input('Could not find spec file. Grep spec dir? (y/N) ') =~? '^y')
  call inputrestore()
  if !yes
    exe cd_back
    return
  endif

  let specs = system("rg -lg '*_spec.rb' " . class_name . ' ' . spec_dir)
  " Grep for the class name under the spec dir
  if empty(specs)
    echom 'Could not find mention of class ' . class_name . ' under ' . spec_dir
  else
    " In almost all cases the class we're testing should only have one
    " file, but if there are several, Run_Rspec_Cmd will call them all.
    call Run_Rspec_Cmd(split(specs, "\n"))
  endif

  " Return to where we were
  exe cd_back
endfunction

function! Run_Spec()
  let s:old_path = getcwd()
  let s:cd_back = 'cd ' . s:old_path

  let repo_root = system('git rev-parse --show-toplevel')
  if empty(repo_root)
    echo "Couldn't find the repo root. It's not a git repo?"
    return
  endif
  let match = matchstr(expand('%:p'), '_spec.rb$')

  " We have a bonafide spec file but we have to leave the spec directory.
  if ! empty(match)
    " cd to the repo root
    exe 'cd ' . repo_root
    call Run_Rspec_Cmd(expand('%'))

    " Return to where we were
    exe 'cd ' . old_path

    " Stop
    return
  endif

  " It's not a spec file, so try to run the most specific spec file
  call Find_And_Run_Spec_File()

  " Return to where we were
  exe 'cd ' . old_path
endfunction
