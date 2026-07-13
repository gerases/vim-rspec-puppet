source plugin/rspec_puppet.vim
call vspec#hint({"scope": "rspec_puppet#scope()", "sid": "rspec_puppet#sid()"})

let g:repo_root = getcwd()
let g:modules_dir = g:repo_root . '/t/data/modules'

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

  it "extracts a define name"
    new
    put =[
    \   'define mymod::my_define (',
    \ ]

    Expect Call("s:Find_Spec_File_From_Puppet_Manifest") == 'mymod::my_define'
  end

  it "ignores indented class keywords"
    new
    put =[
    \   '  class { somepackage:',
    \   '    ensure => installed,',
    \   '  }',
    \ ]

    Expect empty(Call("s:Find_Spec_File_From_Puppet_Manifest")) to_be_true
  end
end

describe "Find_Module_Root"
  exe 'cd ' . g:modules_dir

  after
    Expect getcwd() == g:modules_dir
  end

  it "finds module root from a manifest file"
    silent edit a_module/manifests/init.pp
    Expect Call("s:Find_Module_Root") == g:modules_dir . '/a_module'
  end

  it "finds module root from a spec file"
    silent edit a_module/spec/classes/a_module_spec.rb
    Expect Call("s:Find_Module_Root") == g:modules_dir . '/a_module'
  end

  it "finds module root from a deeply nested manifest"
    silent edit profile/manifests/b/c/d.pp
    Expect Call("s:Find_Module_Root") == g:modules_dir . '/profile'
  end

  it "finds module root from a deeply nested spec"
    silent edit profile/spec/classes/b/c/d_spec.rb
    Expect Call("s:Find_Module_Root") == g:modules_dir . '/profile'
  end
end

describe "Rspec Runner"
  exe 'cd ' . g:modules_dir

  call Call("s:turn_on_test_mode")

  after
    Expect getcwd() == g:modules_dir
  end

  it "works from within a spec file"
    silent edit a_module/spec/classes/a_module_spec.rb
    call Call('Run_Spec')
    Expect Ref("s:rspec_command") =~ 'rspec.* ' . g:modules_dir . '/a_module/spec/classes/a_module_spec.rb'
  end

  it "works from within a component-module puppet file"
    silent edit a_module/manifests/init.pp
    call Call('Run_Spec')
    Expect Ref("s:rspec_command") =~ 'rspec.* ' . g:modules_dir . '/a_module/spec/classes/a_module_spec.rb'
  end

  it "works from within a component-module init.pp when spec is named init_spec.rb"
    silent edit b_module/manifests/init.pp
    call Call('Run_Spec')
    Expect Ref("s:rspec_command") =~ 'rspec.* ' . g:modules_dir . '/b_module/spec/classes/init_spec.rb'
  end

  it "works from within a 1-level-deep profile manifest"
    silent edit profile/manifests/a.pp
    call Call('Run_Spec')
    Expect Ref("s:rspec_command") =~ 'rspec.* ' . g:modules_dir . '/profile/spec/classes/a_spec.rb'
  end

  it "works from within a 3-level-deep profile manifest"
    silent edit profile/manifests/b/c/d.pp
    call Call('Run_Spec')
    Expect Ref("s:rspec_command") =~ 'rspec.* ' . g:modules_dir . '/profile/spec/classes/b/c/d_spec.rb'
  end

  it "works from within a define type manifest"
    silent edit profile/manifests/my_define.pp
    call Call('Run_Spec')
    Expect Ref("s:rspec_command") =~ 'rspec.* ' . g:modules_dir . '/profile/spec/defines/my_define_spec.rb'
  end

  it "appends line number when Run_Spec_Line is used"
    silent edit a_module/spec/classes/a_module_spec.rb
    3
    call Call('Run_Spec_Line')
    Expect Ref("s:rspec_command") =~ 'rspec.* ' . g:modules_dir . '/a_module/spec/classes/a_module_spec.rb:3'
  end

  it "uses --fail-fast flag"
    silent edit a_module/manifests/init.pp
    call Call('Run_Spec')
    Expect Ref("s:rspec_command") =~ '--fail-fast'
  end

  it "uses -fd formatter"
    silent edit a_module/manifests/init.pp
    call Call('Run_Spec')
    Expect Ref("s:rspec_command") =~ '-fd'
  end
end

describe "Spec to manifest"
  exe 'cd ' . g:modules_dir

  after
    enew!
    Expect getcwd() == g:modules_dir
  end

  it "finds init.pp for a single-segment class"
    silent edit a_module/spec/classes/a_module_spec.rb
    Expect Call("s:Find_Manifest_From_Spec") == 'manifests/init.pp'
  end

  it "finds the manifest for a multi-segment class"
    silent edit profile/spec/classes/a_spec.rb
    Expect Call("s:Find_Manifest_From_Spec") == 'manifests/a.pp'
  end

  it "finds the manifest for a deeply nested class"
    silent edit profile/spec/classes/b/c/d_spec.rb
    Expect Call("s:Find_Manifest_From_Spec") == 'manifests/b/c/d.pp'
  end

  it "returns empty string when no describe line exists"
    new
    put =['# just a comment']
    Expect Call("s:Find_Manifest_From_Spec") == ''
    close!
  end
end

describe "Buffer type detection"
  after
    enew!
  end

  it "returns 1 for puppet manifests"
    silent edit a_module/manifests/init.pp
    Expect Call("s:Get_Buf_Type") == 1
  end

  it "returns 2 for spec files"
    silent edit a_module/spec/classes/a_module_spec.rb
    Expect Call("s:Get_Buf_Type") == 2
  end

  it "returns 0 for other files"
    new
    Expect Call("s:Get_Buf_Type") == 0
    close!
  end
end
