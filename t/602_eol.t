#!./perl -w

use Cwd;
use Pod::Html qw( pod2html );
use File::Temp qw( tempdir );
use Test::More tests => 3;

my $cwd = cwd();

{
    my $tdir = tempdir( CLEANUP => 1 );
    chdir($tdir) or die "Unable to change to temporary directory";

    my $podfile = "$$.pod";
    my $infile = "$$.in";
    my @outfile = map { "$$.o$_" } 0..2;
    
    open my $pod, '>', $podfile or die "$podfile: $!";
    print $pod <<__EOF__;
=pod

=head1 NAME

crlf

=head1 DESCRIPTION

crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf
crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf
crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf
crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf

    crlf crlf crlf crlf
    crlf crlf crlf crlf
    crlf crlf crlf crlf

crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf
crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf
crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf
crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf crlf

=cut
__EOF__
    close $pod or die $!;
    
    my $i = 0;
    foreach my $eol ("\r", "\n", "\r\n") {
        open $pod, '<', $podfile or die "$podfile: $!";
        open my $in, '>', $infile  or die "$infile: $!";
        while (<$pod>) {
            s/[\r\n]+/$eol/g;
            print $in $_;
        }
        close $pod or die $!;
        close $in or die $!;
    
        pod2html("--title=eol", "--infile=$infile", "--outfile=$outfile[$i]");
        ++$i;
    }
    
    # --- now test ---
    
    my @cksum;
    
    foreach (0..2) {
        local $/;
        open my $in, '<', $outfile[$_] or die "$outfile[$_]: $!";
        $cksum[$_] = unpack "%32C*", <$in>;
        close $in or die $!;
    }
    
    is($cksum[0], $cksum[1], "CR vs LF");
    is($cksum[0], $cksum[2], "CR vs CRLF");
    is($cksum[1], $cksum[2], "LF vs CRLF");

    chdir($cwd) or die "Cannot change back to starting point";
}

