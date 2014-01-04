use strict;
use warnings;
use Carp;
use Cwd;
use Pod::Html::Auxiliary qw(
    relativize_url
);
use Test::More qw(no_plan); # tests =>  5;

my $cwd = cwd();

test_relativize_url(
    "$cwd/t/htmllink",
    "$cwd/t/crossref.html",
    "./htmllink"
);

test_relativize_url(
    "$cwd/testdir/test.lib/var-copy",
    "$cwd/t/crossref.html",
    "../testdir/test.lib/var-copy"
);

test_relativize_url(
    "$cwd/t/t/crossref",
    "$cwd/t/feature.html",
    "t/crossref"
);

test_relativize_url(
    "t/t/htmlescp",
    "t/htmldir4.html",
    "t/htmlescp"
);

test_relativize_url(
    "t/t/feature",
    "t/htmldir4.html",
    "t/feature"
);

test_relativize_url(
    "",
    "$cwd/t/crossref.html",
    ""
);

test_relativize_url(
    "$cwd/t/",
    "$cwd/t/",
    "./"
);


sub test_relativize_url {
    croak "test_relativize_url(): Needs 3 arguments"
        unless @_ == 3;
    my ($dest, $source, $expected) = @_;
    my $got = relativize_url($dest, $source);
    is($got, $expected, "url relativized to <$got>");
}

