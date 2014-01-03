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
                     'File::Copy' => 0,
                     'File::Path' => 2.08,
                     'File::Temp' => 0.14,
#                     'IO::CaptureOutput' => 0, # for testing only
                    },
    LICENSE     => 'perl',
);

