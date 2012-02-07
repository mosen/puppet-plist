Puppet::Type.newtype(:plist) do
	@doc = "Manage key/value pairs in a plist file by merging the values from the source file to the specified target
    file.

    The source can be a static file or an .erb template. It's up to the user to construct a plist with the correct
    structure to match the target plist file.

    The provider walks the tree of keys and compares the values.

    If the merge parameter is :defaults, values are only set if the corresponding key does not exist.
    If the merge parameter is :enforced, values are overwritten (on every puppet run).

    If the target file doesn't exist then it is created with the contents of the template/file.
  "
	
	newparam(:path) do
		desc "Path to the plist file"
		
		isnamevar
	end

	newproperty(:content) do
	  desc "File or template containing the keys and values to be managed.
	    Typically this should be an .erb template resulting in an xml plist file, so
	    that all of the key values can be set via puppet variables or facter facts."
	  
	end
	
	newparam(:merge) do
	  desc "How to merge the keys and values from the content to the target specified in the path parameter.
	    Keys and values from the content parameter can be merged into the file specified by 'path' in two ways:
	    
	    1. Defaults mode: Key and value from the content are only set in the target if they do not exist.
	    2. Enforced mode: Key and value from the content are set regardless of what already exists in the target."
	  # TODO: should there be a mode for removing specified keys?? I cant think of a use case.
	  defaultto :enforced
	  
	  newvalues(:defaults, :enforced)
	end
	
end