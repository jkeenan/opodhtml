# -*- perl -*-

BEGIN {
    die "Run me from outside the t/ directory, please" unless -d 't';
}

# test the directory cache
# XXX test --flush and %Pages being loaded/used for cross references

use strict;
use Carp;
use Cwd;
use File::Copy;
use File::Path qw( make_path );
use File::Temp qw( tempdir );
use Pod::Html ();
use Pod::Html::Auxiliary qw(
    unixify
);
use lib qw( t/lib );
use Testing qw(
    read_cachefile
);
use Test::More tests =>  5;

my ($options, $p2h, $rv);
my $cwd = Pod::Html::unixify(Cwd::cwd());
my $source_infile = "t/cache.pod";

{
    my $tdir = tempdir( CLEANUP => 1 );
    make_path("$tdir/alpha", "$tdir/beta", "$tdir/gamma", "$tdir/t", {
        verbose => 0,
        mode => 0755,
    });
    my $infile = "$tdir/alpha/cache.pod";
    my $outfile ="cacheout.html",
    copy $source_infile => $infile
        or croak "Unable to copy $infile";
    chdir $tdir or croak "Unable to change to $tdir";
    my $podroot_set = "..";
    my $podpath_set = join(':' => qw( alpha beta gamma ));

    my $cachefile = "pod2htmd.tmp";
    unlink $cachefile;
    is(-f $cachefile, undef, "No cache file to start");
    my %pages = ();
    my %expected_pages = ();
    $options = {
        infile => $infile,
        outfile => $outfile,
        podroot => $podroot_set,
        podpath => $podpath_set,
        htmldir => "$tdir/t",
    };
    $p2h = Pod::Html->new();
    $p2h->process_options( $options );
    $p2h->cleanup_elements();
    $rv = $p2h->generate_pages_cache();
    ok(defined($rv),
        "generate_pages_cache() returned defined value, indicating full run");
    
    is(-f $cachefile, 1, "Cache created");
    my ($podpath, $podroot) = read_cachefile($cachefile);
    is($podpath, $podpath_set, "podpath is $podpath_set");
    is($podroot, $podroot_set, "podroot is $podroot_set");

    chdir $cwd or croak "Unable to change back to $cwd";
}
