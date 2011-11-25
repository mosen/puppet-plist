# Plist type

# The basic idea is that we manage plists similar to how MCX would manage them.
# The end user provides a number of keys and values that should be managed, in the same structure as the target plist.
# The puppet plist type can apply those keys and values similar to MCX's 'Once, Often, Always' types.
# Unfortunately we cannot apply something 'Often' because of how puppet is invoked.
# The provider can operate in two 'merge modes':
# - defaults: only set the keys that do not already exist
# - enforced: always set the values that we specified, every time.
# The content of the file can be specified in the manifest, in a file, or via an .erb template (Very similar to the File resource).

Puppet::Type.newtype(:plist) do
	@doc = "Manage key/value pairs in a plist file by merging from a template."
	
	newparam(:path) do
		desc "Path to the plist file"
		
		isnamevar
	end
	
	# TODO: should be property?
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