package Testing;
use strict;
require Exporter;

our (@ISA, @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw(
    read_cachefile
    read_cachefile_with_pages
    get_expected_pages
    initialize_testing_directory
    get_files_and_dirs
    get_basic_args
    get_expect_and_result
    identify_diff
    print_differences
);

use Carp;
require Config;
use File::Copy;
use File::Path qw( make_path );
use File::Spec;
use File::Temp qw( tempdir );
use Pod::Html::Auxiliary qw(
    unixify
);

=head1 NAME

Testing - functions used in the testing of the Pod-Html distribution

=head1 DESCRIPTION

This package holds non-object-oriented utility functions used in the test
suite for the Pod-Html distribution.  All functions herein are exported on
demand only.

=cut

=head1 SUBROUTINES

=head2 C<read_cachefile()>

=over 4

=item * Purpose

Read the contents of a cachefile and return any C<podpath> and C<podroot>
found therein.

=item * Arguments

    ($podpath, $podroot) = read_cachefile($cachefile)

=item * Return Value

List of two strings.

=item * Comment

Since this function closes the handle to the cachefile before returning, it
cannot be used in cases where you wish to read the cachefile for purposes
beyond simply obtaining values for C<podpath> and C<podroot>.

=back

=cut

sub read_cachefile {
    my $cachefile = shift;
    my ($podpath, $podroot);
    open my $CACHE, '<', $cachefile
        or croak "Cannot open cache file $cachefile";
    chomp($podpath = <$CACHE>);
    chomp($podroot = <$CACHE>);
    close $CACHE or croak "Cannot close cache file $cachefile";
    return ($podpath, $podroot);
}

=head2 C<read_cachefile_with_pages()>

=over 4

=item * Purpose

Like C<read_cachefile>: read the contents of a cachefile and return any
C<podpath> and C<podroot> found therein, but also return a reference to a hash
of pages found therein.

=item * Arguments

    ($podpath, $podroot, $pages) = read_cachefile_with_pages($tcachefile);

=item * Return Value

List of two strings and a hash reference.

=back

=cut

sub read_cachefile_with_pages {
    my $cachefile = shift;
    my ($podpath, $podroot);
    open my $CACHE, '<', $cachefile
        or croak "Cannot open cache file $cachefile";
    chomp($podpath = <$CACHE>);
    chomp($podroot = <$CACHE>);
    my %pages = ();
    while (<$CACHE>) {
        /(.*?) (.*)$/;
        $pages{$1} = $2;
    }
    close $CACHE;
    return ($podpath, $podroot, \%pages);
}

=head2 C<get_expected_pages()>

=over 4

=item * Purpose

Get a list of pages in the C<podpath> directory.

=item * Arguments

    my $expected_pages = get_expected_pages($podpath, $tdir);

List of two directories: the C<podpath> and the one we're returning to, i.e.,
the then current directory.

=item * Return Value

Hash reference.

=item * Comment

=back

=cut

sub get_expected_pages {
    my ($podpath, $tdir) = @_;
    chdir($podpath) or croak "Unable to change to podpath $podpath";
    my %expected_pages =
        # chop off the .pod and set the path
        map { my $f = substr($_, 0, -4); $f => "t/$f" }
        <*.pod>;
    chdir($tdir) or croak "Unable to change back to testing directory $tdir";
    return \%expected_pages;
}

=pod

    $tdir = initialize_testing_directory($start_dir, $podfile);

=cut

sub initialize_testing_directory {
    my ($start_dir, $podfile) = @_;
    my $tdir = tempdir( CLEANUP => 1 );
    chdir $tdir or croak "Unable to change to tempdir";
    make_path('testdir/test.lib', 't', {
        verbose => 0,
        mode => 0755,
    });
    copy("$start_dir/testdir/perlpodspec-copy.pod", 'testdir/test.lib/podspec-copy.pod')
        or croak "Could not copy perlpodspec-copy";
    copy("$start_dir/testdir/perlvar-copy.pod", 'testdir/test.lib/var-copy.pod')
        or croak "Could not copy perlvar-copy!";
    copy "$start_dir/t/$podfile.pod" => "$tdir/t/"
        or croak "Unable to copy $podfile.pod";
    return $tdir;
}

=pod

    $f = get_files_and_dirs($podfile);

=cut

sub get_files_and_dirs {
    my $podfile = shift;
    croak "Must provide stem of basename of pod file" unless $podfile;
    my $cwd = unixify( Cwd::cwd() );
    my ($vol, $dir) = File::Spec->splitpath($cwd, 1);
    my @dirs = File::Spec->splitdir($dir);
    shift @dirs if $dirs[0] eq '';
    my $relcwd = join '/', @dirs;

    my $new_dir  = File::Spec->catdir($dir, "t");
    my $infile   = File::Spec->catpath($vol, $new_dir, "$podfile.pod");
    my $outfile  = File::Spec->catpath($vol, $new_dir, "$podfile.html");
    return {
        volume      => $vol,
        cwd         => $cwd,
        relcwd      => $relcwd,
        infile      => $infile,
        outfile     => $outfile,
    };
}

=pod

    $constructor_args = get_basic_args($tdir, $f);

=cut

sub get_basic_args {
    my ($tdir, $f) = @_;
    return {
      infile      => $f->{infile},
      outfile     => $f->{outfile},
      podpath     => 't',
      htmlroot    => '/',
      podroot     => $tdir,
      quiet       => 1,
    };
}

=pod

    ($expect, $result) = get_expect_and_result($f);

=cut

sub get_expect_and_result {
    my ($f, $expect) = @_;
    $f->{cwd} =~ s|\/$||;
    my $result;
    {
        $expect =~ s/\[PERLADMIN\]/$Config::Config{perladmin}/;
        $expect =~ s/\[RELCURRENTWORKINGDIRECTORY\]/$f->{relcwd}/g;
        $expect =~ s/\[ABSCURRENTWORKINGDIRECTORY\]/$f->{cwd}/g;
        if (ord("A") == 193) { # EBCDIC.
            $expect =~ s/item_mat_3c_21_3e/item_mat_4c_5a_6e/;
        }
        local $/;
        open my $IN, $f->{outfile} or die "cannot open $f->{outfile}: $!";
        $result = <$IN>;
        close $IN or die "cannot close $f->{outfile}: $!";
    }
    return ($expect, $result);
}

=pod

    ($diff, $diffopt) = identify_diff();

=cut

sub identify_diff {
    my $diff = '/bin/diff';
    -x $diff or $diff = '/usr/bin/diff';
    -x $diff or $diff = undef;
    my $diffopt = $diff ? $^O =~ m/(linux|darwin)/ ? '-u' : '-c'
                        : '';
    $diff = 'fc/n' if $^O =~ /^MSWin/;
    $diff = 'differences' if $^O eq 'VMS';
    return ($diff, $diffopt);
}

=pod

    print_differences($podfile, $expect, $diff, $diffopt, $outfile);

=cut

sub print_differences {
    my ($podfile, $expect, $diff, $diffopt, $outfile) = @_;
    my $expectfile = "${podfile}_expected.tmp";
print STDERR "expectfile: $expectfile\n";
    open my $TMP, ">", $expectfile
        or die "Unable to open for writing: $!";
    print $TMP $expect;
    close $TMP or die "Unable to close after writing: $!";
    open my $DIFF_FH, "$diff $diffopt $expectfile $outfile |"
        or die "Unable to open to diff: $!";
    print STDERR "# $_" while <$DIFF_FH>;
    close $DIFF_FH;
    unlink $expectfile;
    return 1;
}

1;
