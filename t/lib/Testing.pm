package Testing;
use strict;
require Exporter;

our (@ISA, @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw(
    read_cachefile
    read_cachefile_with_pages
    get_expected_pages
);

use Carp;
#use Config;
#use File::Spec;
#use File::Spec::Unix;
#use Getopt::Long;
#use locale; # make \w work right in non-ASCII lands

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

1;
