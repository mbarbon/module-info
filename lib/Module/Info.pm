package Module::Info;

use strict;
use File::Spec;
use Config;

use vars qw($VERSION);
$VERSION = 0.04;


=head1 NAME

Module::Info - Information about Perl modules

=head1 SYNOPSIS

  use Module::Info;

  my $mod = Module::Info->new_from_file('Some/Module.pm');
  my $mod = Module::Info->new_from_module('Some::Module');
  my $mod = Module::Info->new_from_loaded('Some::Module');

  my @mods = Module::Info->all_installed('Some::Module');

  my $name    = $mod->name;
  my $version = $mod->version;
  my $dir     = $mod->inc_dir;
  my $file    = $mod->file;
  my $is_core = $mod->is_core;

  # Only available in perl 5.6.1 and up.
  # These do compile the module.
  my @packages = $mod->packages_inside;     **UNIMPLEMENTED**
  my @used     = $mod->modules_used;        **UNIMPLEMENTED**

=head1 DESCRIPTION

Module::Info gives you information about Perl modules B<without
actually loading the module>.

=head1 METHODS

=head2 Constructors

There are a few ways to specify which module you want information for.
They all return Module::Info objects.

=over 4

=item new_from_file

  my $module = Module::Info->new_from_file('path/to/Some/Module.pm');

Given a file, it will interpret this as the module you want
information about.

If the file doesn't exist or isn't readable it will return false.

=cut

sub new_from_file {
    my($proto, $file) = @_;
    my($class) = ref $proto || $proto;

    return unless -r $file;

    my $self = {};
    $self->{file} = File::Spec->rel2abs($file);
    $self->{dir}  = '';
    $self->{name} = '';

    return bless $self, $class;
}

=item new_from_module

  my $module = Module::Info->new_from_module('Some::Module');
  my $module = Module::Info->new_from_module('Some::Module', @INC);

Given a module name, @INC will be searched and the first module found
used.  This is the same module that would be loaded if you just say
C<use Some::Module>.

If you give your own @INC, that will be used to search instead.

=cut

sub new_from_module {
    my($class, $module, @inc) = @_;
    return ($class->_find_all_installed($module, 1, @inc))[0];
}

=item new_from_loaded

  my $module = Module::Info->new_from_loaded('Some::Module');

Gets information about the currently loaded version of Some::Module.
If it isn't loaded, returns false.

=cut

sub new_from_loaded {
    my($class, $name) = @_;

    my $mod_file = join('/', split('::', $name)) . '.pm';
    my $filepath = $INC{$mod_file} || '';

    my $module = Module::Info->new_from_file($filepath);
    $module->{name} = $name;
    ($module->{dir} = $filepath) =~ s|/?$mod_file$||;
    $module->{dir} = File::Spec->rel2abs($module->{dir});

    return $module;
}

=item all_installed

  my @modules = Module::Info->all_installed('Some::Module');
  my @modules = Module::Info->all_installed('Some::Module', @INC);

Like new_from_module(), except I<all> modules in @INC will be
returned, in the order they are found.  Thus $modules[0] is the one
that would be loaded by C<use Some::Module>.

=cut

sub all_installed {
    my($class, $module, @inc) = @_;
    return $class->_find_all_installed($module, 0, @inc);
}

# Thieved from Module::InstalledVersion
sub _find_all_installed {
    my($proto, $name, $find_first_one, @inc) = @_;
    my($class) = ref $proto || $proto;

    @inc = @INC unless @inc;
    my $file = File::Spec->catfile(split /::/, $name) . '.pm';
    
    my @modules = ();
    DIR: foreach my $dir (@inc) {
        my $filename = File::Spec->catfile($dir, $file);
        if( -r $filename ) {
            my $module = $class->new_from_file($filename);
            $module->{dir} = File::Spec->rel2abs($dir);
            $module->{name} = $name;
            push @modules, $module;
            last DIR if $find_first_one;
        }
    }
              
    return @modules;
}


=back

=head2 Information without loading

The following methods get their information without actually compiling
the module.

=over 4

=item B<name>

  my $name = $module->name;

Name of the module (ie. Some::Module).  Module loaded using
new_from_file() won't have this information.

=cut

sub name {
    my($self) = shift;
    return $self->{name};
}

=item B<version>

  my $version = $module->version;

Divines the value of $VERSION.  This uses the same method as
ExtUtils::MakeMaker and all caveats therein apply.

=cut

# Thieved from ExtUtils::MM_Unix 1.12603
sub version {
    my($self) = shift;

    my $parsefile = $self->file;

    open(MOD, $parsefile) or die $!;

    my $inpod = 0;
    my $result;
    while (<MOD>) {
        $inpod = /^=(?!cut)/ ? 1 : /^=cut/ ? 0 : $inpod;
        next if $inpod || /^\s*#/;

        chomp;
        next unless /([\$*])(([\w\:\']*)\bVERSION)\b.*\=/;
        my $eval = qq{
                      package Module::Info::_version;
                      no strict;

                      local $1$2;
                      \$$2=undef; do {
                          $_
                      }; \$$2
        };
        local $^W = 0;
        $result = eval($eval);
        warn "Could not eval '$eval' in $parsefile: $@" if $@;
        $result = "undef" unless defined $result;
        last;
    }
    close FH;
    return $result;
}


=item B<inc_dir>

  my $dir = $module->inc_dir;

Include directory in which this module was found.  Module::Info
objects created with new_from_file() won't have this info.

=cut

sub inc_dir {
    my($self) = shift;

    return $self->{dir};
}

=item B<file>

  my $file = $module->file;

The absolute path to this module.

=cut

sub file {
    my($self) = shift;

    return $self->{file};
}

=item B<is_core>

  my $is_core = $module->is_core;

Checks if this module is the one distributed with Perl.

B<NOTE> This goes by what directory it's in.  It's possible that the
module has been altered or upgraded from CPAN since the original Perl
installation.

=cut

sub is_core {
    my($self) = shift;

    return scalar grep $self->{dir} eq $_, ($Config{installarchlib},
                                            $Config{installprivlib});
}

=back

=head2 Information that requires loading.

The following methods get their information by compiling the module
and examining the opcode tree.  They will only work on 5.6.1 and up.

They're also unimplemented.

=over 4

=item B<packages_inside> *UNIMPLEMENTED*

  my @packages = $module->packages_inside;

Looks for any explicit C<package> declarations inside the module and
returns a list.  Useful for finding hidden classes and functionality
(like Tie::StdHandle inside Tie::Handle).

=cut

sub packages_inside { die "UNIMPLEMENTED" }

=item B<modules_used> *UNIMPLEMENTED*

  my @used = $module->modules_used;

Returns a list of all modules which may be C<use>'d or C<require>'d by
this module.

B<NOTE> These modules may be conditionally loaded, can't tell.  Also
can't find modules which might be used inside an C<eval>.

=cut

sub modules_used { die "UNIMPLEMENTED" }

=back

=head1 AUTHOR

Michael G Schwern <schwern@pobox.com> with code from ExtUtils::MM_Unix
and Module::InstalledVersion.

=cut

return 'Stepping on toes is what Schwerns to best!  *poing poing poing*';

