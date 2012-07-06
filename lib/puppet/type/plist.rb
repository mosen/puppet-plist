Puppet::Type.newtype(:plist) do

  @doc = "
  Manage single keys inside a plist file.

  This resource type is primarily intended where you want control over a single key and value inside a plist file, and
  where the value is a simple non-hierarchical value such as an integer or string.

  The path to the plist and the key that you would like to modify are constructed similar to the PlistBuddy(8) command
  line utility, eg, if i want to change the value of a key called childkey in file.plist, the name of the resource would
  be like this:

  /full/path/to/file.plist:parentkey:childkey

  - The full path to the .plist file comes first.
  - Then a colon indicates the root of the plist dictionary.
  - And finally the name of the key in the plist we want to change.
  - If the key is a child of the value of another key, use colons to separate the key names (or indexes).
  "

  ensurable

  attr_accessor :filename
  attr_accessor :keys

  def value_type
    return value(:value_type) if !value(:value_type).nil?

    inferred_type(value(:value))
  end

  # Try to guess the CFPropertyList type based on the value
  def inferred_type(value)
    case value
      when Array then :array
      when Hash then :dict
      when %r{^\d+$} then :integer
      when %r{^\d*\.\d+$} then :real # Doesnt really catch all valid real numbers.
      when true || false then :bool
      when %r{^\d{4}-\d{2}-\d{2}} then :date # Not currently supported, requires munging to native Date type
      else
        :string
    end
  end

  newparam(:path) do
    desc "Path to the plist file and the key inside it (a colon separates child and parent keys), in the form:

    /full/path/to/file.plist:parentkey:childkey
    "

    isnamevar

    munge do |value|
      parts = value.split(/:/)
      @resource.filename = parts.shift
      @resource.keys = parts

      value
    end
  end

  newparam(:value) do
    desc "The value assigned to the specified key."
  end

  newparam(:value_type) do
    desc "The suggested native type of the value. Without this, you will get the inferred best guess."

    newvalues(:string)
    newvalues(:array)
    newvalues(:dict)
    newvalues(:bool)
    newvalues(:real)
    newvalues(:integer)
    newvalues(:date)
    newvalues(:data)
  end

end