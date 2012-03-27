Puppet Plist Resource Type (plist) - Merging Provider Concept
=============================================================

This is an in-progress proof of concept for a plist resource type in puppet.

Design
------

Puppet requires one variable to be established as the unique identifier. For this we use
the path and filename of the plist to modify, rather than an abstract of name and key/path to key.

For the plist provider we establish a behaviour similar to MCX.
The content or source file is merged with the target file in one of two ways, having a similar effect as the MCX
Always and Once policies.

The content of the plist file is specified as an .erb template, which suits dynamic subsitution of values, or we can use
a static file.

In any case, if the keys don't exist in the target they are set based on the template (source) plist.

Caveats
-------

Two puppet modules cannot manage the same resource, at the file level.

Future solution: allow the plist resource to specify a key path to start managing from (subtree management).

Example
-------

```

    class plist_test {

        notify { "Running plist testing manifest": }

        # This is a very rudimentary demonstration of the plist provider proof of concept.
        # The 'Testing' key from this plist should be forced to True

        $plist_content = '<?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>Testing</key>
                <true/>
            </dict>
            </plist>'


        plist { "/tmp/test.plist":
            # This should be replaced with the same content property as the 'File' type.
            content => $plist_content,
            merge => enforced,
        }
    }

    node default {
	    include plist_test
    }
```

Puppet Plist Key/Value Pair (plistkv) Concept
=============================================

This is an in-progress proof of concept for managing single key/value pairs inside a specific property list file.

Design
------

As puppet requires an identifier to be unique for each puppet resource, we need to combine both the file system path,
and the path to the key inside the file.

For this we use a commonly used syntax, with the colon character as the separator between parent and child keys.

Eg.

    plistkv { "/tmp/test.plist:apples:oranges" ...

To manage the key called "oranges" which is a child of the key called "apples" (Inside the file /tmp/test.plist).

This resource is ensurable to provide the setting and deleting of keys from property lists.

Example
-------

This example sets the value of the key "testkey" to "testvalue".

```
        plistkv { "/tmp/test.plist:testkey":
            ensure     => present,
            value      => "testvalue",
            value_type => string,
        }
```
