package Foo;

use strict;
require Exporter;
require "t/lib/Foo.pm";
use vars qw(@ISA);

@ISA = qw(This That What::Ever);

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

wibble('this is the function call');
{ no strict 'refs'; &{'wibble'}('this is a symref function call'); }
Foo->wibble('bar');
my $obj = bless {};
$obj->wibble('bar');
my $method = 'wibble';
Foo->$method;
$obj->$method;
$obj->$method('bar');
Foo->$method('bar');
{
    no strict 'subs';
    $Foo::obj = bless {};
    $Foo::obj->wibble(main::STDOUT);
}

require 5.004;
use 5.004;
require 5;
use 5;
use lib qw(blahbityblahblah);

eval "require Text::Soundex";
