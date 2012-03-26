Puppet::Type.newtype(:plistkv) do
  @doc = "
  Manage single keys inside a plist file.

  This resource type is primarily intended where you want control over a single key and value inside a plist file, and
  where the value is a simple non-hierarchical value such as an integer or string.

  The path to the plist and the key that you would like to modify are constructed similar to the PlistBuddy(8) command
  line utility, that is:

  - The full path to the .plist file comes first.
  - Then a colon indicates the root of the plist dictionary.
  - And finally the name of the key in the plist we want to change.
  - If the key is a child of the value of another key, use colons to separate the key names (or indexes).

  Eg.

  /full/path/to/file.plist:parentkey:childkey

  To change the value of childkey in the file file.plist.
  "

  ensurable

  feature :plist, "The ability to parse and generate .plist files in binary and xml formats."

  newparam(:path) do
    desc "Path to the plist file and the key inside it, in the form:

    /full/path/to/file.plist:parentkey:childkey
    "

    isnamevar
  end

  newparam(:value) do
    desc "The value assigned to the specified key."
  end

end