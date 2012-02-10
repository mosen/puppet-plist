

Puppet::Type.newtype(:plist) do
	@doc = "Manage key/value pairs in a plist file by merging the values from the source file to the specified target
    file.

    The source can be a static file or an .erb template. It's up to the user to construct a plist with the correct
    structure to match the target plist file.

    The provider walks the tree of keys and compares the values.

    If :force is false, values are only set if the corresponding key does not exist. (no overwrite).
    If :force is true, values are overwritten (on every puppet run).

    If the target key doesn't exist, it is always set.
    If the target file doesn't exist, then it is created with the contents of the template/file.
  "

  feature :plist, "The ability to parse and generate .plist files in binary and xml formats."
	
	newparam(:path, :parent => Puppet::Parameter::Path) do
		desc "Path to the plist file"
		
		isnamevar
	end

	newproperty(:content) do
	  desc "Plist content describing keys and values to be enforced.

    You only need to supply the keys and values that need to be changed, not the entire
    plist structure of the target file.
    "

    def property_matches?(current, desired)
      # parse desired, diff to current via hash.diff
    end

    # TODO: validate content as parseable plist.
    def should_to_s(v)
      puts 'should'
      v.inspect
    end

    def is_to_s(v)
      puts 'is'
      v.inspect
    end

    def change_to_s(before, after)
      puts 'Changed'
      puts before.inspect
      puts after.inspect
    end

	end
	
	newparam(:force) do
	  desc "Whether to force values (true) or only set them once (false)"
	  # TODO: A third possible mode might be to delete keys that are absent in the content plist.

	  defaultto :true
	  
	  newvalues(:true, :false)
	end
	
end