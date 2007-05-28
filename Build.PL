require 5.004;

use strict;
use Module::Build;

Module::Build->new( module_name       => 'Module::Info',
                    dist_version_from => 'lib/Module/Info.pm',
                    license           => 'perl',
                    requires          => { 'File::Spec' => 0.08 },
                    script_files      => [qw(bin/pfunc bin/module_info)],
                    dynamic_config    => 0,
                    dist_author       => 'Mattia Barbon <mbarbon@cpan.org>',
                   )->create_build_script;
