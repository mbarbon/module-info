package Foo;

use strict;
require Exporter;
require "lib/Foo.pm";

my $foo = 42;

{
    package Bar;

    my $bar = 23;
}

sub wibble {
    package Wibble;
    $foo = 42;
    return 66;
}
