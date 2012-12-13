node default {

    Plist {
        provider => plistbuddy,
    }

    # Basic Types

    plist { "/tmp/test.plist:basic_string":
        value      => "foobar",
        value_type => string,
    }

    plist { "/tmp/test.plist:basic_boolean_false":
        value      => false,
        value_type => bool,
    }

    plist { "/tmp/test.plist:basic_boolean_true":
        value      => true,
        value_type => bool,
    }

    plist { "/tmp/test.plist:basic_integer":
        value      => 10101,
        value_type => integer,
    }

    plist { "/tmp/test.plist:basic_date":
        value      => "2012-01-01", # Notice we are casting from ISO8601
        value_type => date,
    }

    plist { "/tmp/test.plist:basic_real":
        value      => 3.14159,
        value_type => real,
    }

    # Structured Types

    plist { "/tmp/test.plist:struct_array":
        value      => [ 'foo', 'bar', 'baz' ], # At present, limited to strings
        value_type => array,
    }

    # Not yet supported
    #plist { "/tmp/test.plist:struct_hash":
    #    ensure     => present,
    #    value      => { 'foo' => 'bar', 'baz' => 'bing' },
    #    value_type => hash,
    #}

    # Anything beyond a 1 deep array or hash should use a fragment w/merging.
}