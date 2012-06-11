# Puppet Plist Resource Type (plist) #

This is an in-progress proof of concept for a plist resource type in puppet. It's alpha!

A lot of this document is to provide me with a plan as much as it is to provide people with an idea of how the type
will work.

## Roadmap ##

Initially the resource type will only provide single key/value pair support. As a way of mitigating huge puppet
manifests it should also eventually support plist fragments via template files. The provider will use either `PlistBuddy`
or `defaults` to get support up and running for simple key/value modifications. Later versions of the provider should
incorporate `CFPropertyList` to transform plist structure to ruby and back.

Plist support should be added in the following order:

### Version 1 ###

1. Support for changing single key/value pairs (bool, number, string)
2. Support for changing single key/value pairs (date)

### Version 2 ###

3. Support for changing single key/value pairs with structured (array, hash) values
4. Support for NSData type values.

### Version 3 ###

5. Support for inserting/merging plist fragments into a named plist file.

## Design ##

Puppet requires one variable to be established as the unique identifier. The filename can't be the unique key because
a single puppet resource would need to declare the entire list of modifications to the file. Also, compositing a set of
 changes from a list of classes assigned to a node just wouldn't work (you'd get a kind of namespace clash on the plist
filename).

The proposed format (which is pretty similar to the format defined by **PlistBuddy(8)**:

`/path/to/filename.plist:keyname:childkeyname`

This format ensures that you can have several individual resources declared to modify different sections of a plist file.

## Special Considerations ##

+ The puppet DSL only supports hashes as of version 2.6.0.
+ Delcaration of arrays and hashes in the puppet DSL implies the type of the value. We need a way to explicitly define
the value type, and a reasonable way of guessing the type when converted.
+ It's not clear what type of encoding or formatting should be used for Date and NSData values. Dates should probably be
specified in ISO8601. Data should probably be base64 encoded.
+ There could be a use case where we need to append to the end of an array inside a plist without modifying the existing
array elements
+ Implicit conversion of types might get hairy, so should be given some consideration.

## v1 syntax: Using booleans, numbers and strings ##

If ensure is set to **present**, the provider expects that the key, the value, and the value type all match what we
expect.

If ensure is set to **absent**, the key and all of its descendants are removed from the plist.

The following examples make use of implicit type conversion.

    plist { "/tmp/test.plist:boolkey":
        ensure     => present,
        value      => true,
    }

*Example 1a: Setting a boolean value*

    plist { "/tmp/test.plist:numkey":
        ensure     => present,
        value      => 10,
    }

*Example 1b: Setting a number value*

    plist { "/tmp/test.plist:strkey":
        ensure     => present,
        value      => "some string value",
    }

*Example 1c: Setting a string value*

If you would like to explicitly define the type that will be used in the plist file then you can use the **value_type**
parameter.


    plist { "/tmp/test.plist:strkey":
        ensure     => present,
        value      => "some string value",
        value_type => string,
    }

*Example 1d: Setting a value with an explicit type*

## v1 syntax: using dates ##

The date format should be represented as an ISO8601 date, with or without time as needed.

    plist { "/tmp/test.plist:datekey":
        ensure     => present,
        value      => "2012-01-01",
        value_type => date,
    }

*Example 1e: Setting a date*

    plist { "/tmp/test.plist:datekey":
        ensure     => present,
        value      => "2012-01-01T14:30",
        value_type => date,
    }

*Example 1f: Setting a date and time*

## v2 syntax: using arrays and hashes ##

The puppet DSL support for arrays and hashes is fairly simple, so there are a couple of limitations when using the plist
type to describe these kinds of values:

+ Support for arrays will be limited to unstructured values where all elements are the same type.
+ Support for hashes will be limited to implicit type conversion of all hash values.
+ Nested arrays and hashes are generally not supported here.

If you would like to create something more complex, like an array of dictionaries containing many different values, then
you will have to resort to constructing xml templates to produce a plist fragment, which then gets merged into the plist.

In these array examples, any existing array values are replaced.

    plist { "/tmp/test.plist:arraykey":
        ensure     => present,
        value      => [ "foo", "bar", "baz" ],
    }

*Example 2a: Setting simple array values*

    plist { "/tmp/test.plist:arraykey":
        ensure     => present,
        value      => [ "2011-01-01", "2011-02-01", "2011-03-01" ],
        value_type => date,
    }

*Example 2b: Force all values to use one type*

    plist { "/tmp/test.plist:hashkey":
        ensure     => present,
        value      => { key1 => "somestring", key2 => "2012-03-01" },
    }

*Example 2c: A hash with mixed types of values, the provider will guess how to convert the type*

## v3 syntax: using plist fragments ##

In order to create more complex structures inside a plist file, we have to go outside of the puppet language.

You should create an xml plist using XCode or any property list editor with the exact structure you would like to
manage. Some property list editors let you copy and paste entire structures from a vendors plist into an empty plist.

From here, you can go about creating an erb template based on the xml formatted version of that plist, removing any
values you hardcoded into the template and replacing them with puppet variables. With this fragment you manage whole
sections of a plist by declaring the variable substitutions either locally (inside the manifest), or by using an ENC to
supply those values.

So, here's a walkthrough of what theoretically needs to happen:

First, create an erb template with the xml contents of the plist structure you want to manage. It doesn't have to replicate
the parent elements of the things you want to manage, the resource type should be able to merge the structure at any
given path. Here I made a simple plist with one setting:


    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>SleepTime</key>
        <integer><%= $sleep_time %></integer>
    </dict>
    </plist>

*Example 3a: test.plist.erb*

This plist fragment will make sure that there is a key SleepTime with an integer value of whatever we declare as
$sleep_time.

Second, declare a manifest that uses the template and sets the value of $sleep_time, it should look something like this.

    class plist-test {

        $sleep_time = 30

        plist_fragment { "/tmp/test.plist:path:to:managed:section":
            ensure => present,
            value  => template('test.plist.erb'),
        }

    }

The plist_fragment type will then make sure the following things are true:

+ The file /tmp/test.plist exists, if not it will be created.
+ The path to the key :path:to:managed:section exists, if not it will be created as nested NSDicts (dictionaries).
+ The parsed plist template has keys and values equal to all of the child keys and values of :path:to:managed:section
+ All of those values have the same type as the ones in the template.

If any of the values or types are mismatched then they are overwritten with the ones specified inside the erb template.

