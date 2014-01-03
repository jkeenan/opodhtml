#!/usr/bin/perl -w                                         # -*- perl -*-

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
use Test::More tests => 31;

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
    my $tcachefile = "t/pod2htmd.tmp";
    unlink $cachefile;
    is(-f $cachefile, undef, "No cache file to start");
    is(-f $tcachefile, undef, "No cache file to start");

    # I.
    # test podpath and podroot
    {
        $options = {
            infile => $infile,
            outfile  => $outfile,
            podpath => "scooby:shaggy:fred:velma:daphne",
            podroot => $tdir,
        };
        $p2h = Pod::Html->new();
        $p2h->process_options( $options );
        $p2h->cleanup_elements();
        $rv = $p2h->generate_pages_cache();
        ok(defined($rv),
            "generate_pages_cache() returned defined value, indicating full run");
        is(-f $cachefile, 1, "Cache $cachefile created");
        my ($podpath, $podroot);
        open my $CACHE, '<', $cachefile or die "Cannot open cache file: $!";
        chomp($podpath = <$CACHE>);
        chomp($podroot = <$CACHE>);
        close $CACHE;
        is($podpath, "scooby:shaggy:fred:velma:daphne", "podpath");
        is($podroot, $tdir, "podroot");
    }

    # II.
    # test cache contents
    {
        my %pages = ();
        my %expected_pages = ();
        $options = {
            infile => $infile,
            outfile  => $outfile,
            cachedir => 't',
            podpath => 't',
            htmldir => $tdir,
        };
        $p2h = Pod::Html->new();
        $p2h->process_options( $options );
        $p2h->cleanup_elements();
        my $ucachefile = $p2h->get('Dircache');
        ok( ! (-f $ucachefile), "'Dircache' set but file $ucachefile does not exist");
        $rv = $p2h->generate_pages_cache();
        ok(defined($rv),
            "generate_pages_cache() returned defined value, indicating full run");
        is(-f $tcachefile, 1, "Cache $tcachefile created");
        my ($podpath, $podroot);
        open my $CACHE, '<', $tcachefile or die "Cannot open cache file: $!";
        chomp($podpath = <$CACHE>);
        chomp($podroot = <$CACHE>);
        is($podpath, "t", "podpath");
        %pages = ();
        while (<$CACHE>) {
            /(.*?) (.*)$/;
            $pages{$1} = $2;
        }
        chdir("t");
        %expected_pages =
            # chop off the .pod and set the path
            map { my $f = substr($_, 0, -4); $f => "t/$f" }
            <*.pod>;
        chdir($tdir);
        is_deeply(\%pages, \%expected_pages, "cache contents");
        close $CACHE;
        ok( (-f $ucachefile), "'Dircache' now set and file $ucachefile exists");

        # IIa.
        # Now that the cachefile exists, we'll conduct another run to exercise
        # other parts of the code.
        $rv = $p2h->generate_pages_cache();
        ok(! defined($rv),
            "generate_pages_cache() returned undefined value, indicating no need for full run");
    }
    chdir($cwd) or croak "Unable to change back to starting point";
} # end of $tdir block

########## Tests for verbose output ##########

{
    # III.
    # test podpath and podroot

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
    my $tcachefile = "t/pod2htmd.tmp";
    unlink $cachefile;
    is(-f $cachefile, undef, "No cache file to start");
    is(-f $tcachefile, undef, "No cache file to start");

    {
        $options = {
            infile => $infile,
            outfile  => $outfile,
            podpath => "scooby:shaggy:fred:velma:daphne",
            podroot => $tdir,
            verbose => 1,
        };
        $p2h = Pod::Html->new();
        $p2h->process_options( $options );
        $p2h->cleanup_elements();
        {
            my $stdout;
            open my $FH, '>', \$stdout
                or die "Unable to open for writing to scalar: $!";
            my $oldFH = select $FH;
            my $warning = '';
            local $SIG{__WARN__} = sub { $warning = $_[0]; };
            $rv = $p2h->generate_pages_cache();
            select $oldFH;
            close $FH;

            ok(defined($rv),
                "generate_pages_cache() returned defined value, indicating full run");
            like($warning, qr/caching directories for later use/s,
                "generate_pages_cache(): verbose: caching directories");
        }
        is(-f $cachefile, 1, "Cache created");
        my ($podpath, $podroot);
        open my $CACHE, '<', $cachefile or die "Cannot open cache file: $!";
        chomp($podpath = <$CACHE>);
        chomp($podroot = <$CACHE>);
        close $CACHE;
        is($podpath, "scooby:shaggy:fred:velma:daphne", "podpath");
        is($podroot, $tdir, "podroot");
    }

    # IV.
    # test cache contents
    {
        my %pages = ();
        my %expected_pages = ();

        $options = {
            infile => $infile,
            outfile  => $outfile,
            cachedir => 't',
            podpath => 't',
            htmldir => $tdir,
            verbose => 1,
        };
        $p2h = Pod::Html->new();
        $p2h->process_options( $options );
        $p2h->cleanup_elements();
        {
            my $stdout;
            open my $FH, '>', \$stdout
                or die "Unable to open for writing to scalar: $!";
            my $oldFH = select $FH;
            my $warning = '';
            local $SIG{__WARN__} = sub { $warning = $_[0]; };
            $rv = $p2h->generate_pages_cache();
            select $oldFH;
            close $FH;

            ok(defined($rv),
                "generate_pages_cache() returned defined value, indicating full run");
            like($warning, qr/caching directories for later use/s,
                "generate_pages_cache(): verbose: caching directories");
        }
        is(-f $tcachefile, 1, "Cache created");
        my ($podpath, $podroot);
        open my $CACHE, '<', $tcachefile or die "Cannot open cache file: $!";
        chomp($podpath = <$CACHE>);
        chomp($podroot = <$CACHE>);
        is($podpath, "t", "podpath");
        %pages = ();
        while (<$CACHE>) {
            /(.*?) (.*)$/;
            $pages{$1} = $2;
        }
        chdir("t");
        %expected_pages =
            # chop off the .pod and set the path
            map { my $f = substr($_, 0, -4); $f => "t/$f" }
            <*.pod>;
        chdir($tdir);
        is_deeply(\%pages, \%expected_pages, "cache contents");
        close $CACHE;

        # IVa.
        # Now that the cachefile exists, we'll conduct another run to exercise
        # other parts of the code.
        {
            my $stdout;
            open my $FH, '>', \$stdout
                or die "Unable to open for writing to scalar: $!";
            my $oldFH = select $FH;
            my $warning = '';
            local $SIG{__WARN__} = sub { $warning = $_[0]; };
            $rv = $p2h->generate_pages_cache();
            select $oldFH;
            close $FH;

            ok(! defined($rv),
                "generate_pages_cache() returned undefined value, indicating no need for full run");
            like(
                $warning,
                qr/loading directory cache/s,
                "got verbose output: loading",
            );
        }
    }

    {
        $options = {
            infile => $infile,
            outfile  => $outfile,
            podpath => "scooby:shaggy:fred:velma:daphne",
            podroot => "..",
        };
        $p2h = Pod::Html->new();
        $p2h->process_options( $options );
        $p2h->cleanup_elements();
        $rv = $p2h->generate_pages_cache();
        ok(defined($rv),
            "generate_pages_cache() returned defined value, indicating full run");
        is(-f $cachefile, 1, "Cache created");
        my ($podpath, $podroot);
        open my $CACHE, '<', $cachefile or die "Cannot open cache file: $!";
        chomp($podpath = <$CACHE>);
        chomp($podroot = <$CACHE>);
        close $CACHE;
        is($podpath, "scooby:shaggy:fred:velma:daphne", "podpath");
        is($podroot, "..", "podroot");
    }
    chdir $cwd or croak "Unable to change back to $cwd";
} # end of 2nd $tdir
