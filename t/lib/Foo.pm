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

require 5.004;
use 5.004;
require 5;
use 5;
use lib qw(blahbityblahblah);

eval "require Text::Soundex";
