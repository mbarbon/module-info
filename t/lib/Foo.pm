package Foo;

$foo = 42;

{
    package Bar;

    $bar = 23;
}

sub wibble {
    package Wibble;
    $foo = 42;
    return 66;
}
