use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Pod::Html',
    VERSION_FROM => 'lib/Pod/Html.pm',
    AUTHOR       => 'Tom Christiansen <tchrist@perl.com>',
    ABSTRACT     => 'Present Perl documentation in HTML format',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'Carp' => 0,
                     'Cwd' => 0,
                     'IO::File' => 0,
                     'Scalar::Util' => 0, # verify
#                     'IO::CaptureOutput' => 0, # for testing only
                    },
    LICENSE     => 'perl',
);

