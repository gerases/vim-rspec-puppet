source plugin/rspec_puppet.vim
call vspec#hint({"scope": "rspec_puppet#scope()", "sid": "rspec_puppet#sid()"})

describe "Class name extractor"
  after
   close!
  end

  it "extracts simple class name"
    new
    put =[
    \   'class someclass()',
    \ ]

    Expect Call("s:Find_Spec_File_From_Puppet_Manifest") == 'someclass'
  end

  it "extracts compounded class name"
    new
    put =[
    \   'class parent::child::grandchild()',
    \ ]

    Expect Call("s:Find_Spec_File_From_Puppet_Manifest") == 'parent::child::grandchild'
  end
end

describe "Rspec Runner"
  let g:repo_root = getcwd()
  let g:modules_dir = g:repo_root . '/t/data/modules'
  exe 'cd ' . g:modules_dir

  after
    " Ensure we're always back in the original directory after a given test
    " was run
    Expect getcwd() == g:modules_dir
  end

  it "works from within a spec file"
    edit a_module/spec/classes/a_module_spec.rb
    call Call("Run_Spec", 1)
    Expect Ref("s:rspec_command") =~ 'rspec.* ' . g:modules_dir . '/a_module/spec/classes/a_module_spec.rb'
  end

  it "works from within a component-module puppet file"
    edit a_module/manifests/init.pp
    call Call("Run_Spec", 1)
    Expect Ref("s:rspec_command") =~ 'rspec.* spec/classes/a_module_spec.rb'
  end

  it "works from within a 1-level-deep profile manifest"
    edit profile/manifests/a.pp
    call Call("Run_Spec", 1)
    Expect Ref("s:rspec_command") =~ 'rspec.* spec/classes/a_spec.rb'
  end

  it "works from within a 3-level-deep profile manifest"
    edit profile/manifests/b/c/d.pp
    call Call("Run_Spec", 1)
    Expect Ref("s:rspec_command") =~ 'rspec.* spec/classes/b/c/d_spec.rb'
  end
end
