#!/usr/bin/perl -w

use strict;
use lib 't/lib';
use Test::More tests => 8;
use Module::Info;

my $moo = Module::Info->new_from_module( 'Moo' );

is( $moo->version, '0.12' );
is( $moo->safe, 0 );
isa_ok( $moo, 'Module::Info::Unsafe' );

my $safe_moo = Module::Info->new_from_module( 'Moo' );
$safe_moo->safe(1);

is( $safe_moo->safe, 1 );
isa_ok( $safe_moo, 'Module::Info::Safe' );

eval {
    $safe_moo->version;
};
isnt( $@, undef, '$Moo::VERSION is unsafe' );

my $safe_foo = Module::Info->new_from_module( 'Foo' );
$safe_foo->safe(1);

eval {
    is( $safe_foo->version, '7.254' );
};
is( $@, '', '$Foo::VERSION is safe' );
