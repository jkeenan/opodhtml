#!/usr/bin/perl -w                                         # -*- perl -*-

BEGIN {
    die "Run me from outside the t/ directory, please" unless -d 't';
}

use strict;
use Cwd;
use Pod::Html qw(pod2html);
use Pod::Html::Auxiliary qw(
    unixify
);
use Test::More tests =>  5;

my $cwd = Pod::Html::unixify(Cwd::cwd());
my $infile = "t/cache.pod";
my $outfile = "cacheout.html";
my $cachefile = "pod2htmd.tmp";
my $tcachefile = "t/pod2htmd.tmp";
my ($podpath, $podroot);

unlink $cachefile, $tcachefile;
is(-f $cachefile, undef, "No cache file to start");
is(-f $tcachefile, undef, "No cache file to start");

my $rv = pod2html(
    "--infile=$infile",
    "--outfile=$outfile",
    "--podpath=scooby:shaggy:fred:velma:daphne",
    "--podroot=$cwd",
);
ok($rv, "pod2html() returned true value");

# Cleanup
1 while unlink $outfile;
1 while unlink $cachefile;
1 while unlink $tcachefile;
is(-f $cachefile, undef, "No cache file to end");
is(-f $tcachefile, undef, "No cache file to end");
__END__

