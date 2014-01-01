package Pod::Html;
use strict;
require Exporter;

use vars qw($VERSION @ISA @EXPORT);
$VERSION = 1.21;
@ISA = qw(Exporter);
@EXPORT = qw(pod2html);

use Carp;
use Config;
use Cwd;
use File::Basename;
use File::Spec;
use File::Spec::Unix;
use Getopt::Long;
use Pod::Simple::Search;
use lib ( './lib' );
use Pod::Html::Auxiliary qw(
    parse_command_line
    usage
    html_escape
    htmlify
    anchorify
    unixify
);

BEGIN {
    if($Config{d_setlocale}) {
        require locale; import locale; # make \w work right in non-ASCII lands
    }
}

=head1 NAME

Pod::Html - module to convert pod files to HTML

=head1 SYNOPSIS

    use Pod::Html;
    pod2html([options]);

=head1 DESCRIPTION

Converts files from pod format (see L<perlpod>) to HTML format.  It
can automatically generate indexes and cross-references, and it keeps
a cache of things it knows how to cross-reference.

=head1 FUNCTIONS

=head2 pod2html

    pod2html("pod2html",
             "--podpath=lib:ext:pod:vms",
             "--podroot=/usr/src/perl",
             "--htmlroot=/perl/nmanual",
             "--recurse",
             "--infile=foo.pod",
             "--outfile=/perl/nmanual/foo.html");

pod2html takes the following arguments:

=over 4

=item backlink

    --backlink

Turns every C<head1> heading into a link back to the top of the page.
By default, no backlinks are generated.

=item cachedir

    --cachedir=name

Creates the directory cache in the given directory.

=item css

    --css=stylesheet

Specify the URL of a cascading style sheet.  Also disables all HTML/CSS
C<style> attributes that are output by default (to avoid conflicts).

=item flush

    --flush

Flushes the directory cache.

=item header

    --header
    --noheader

Creates header and footer blocks containing the text of the C<NAME>
section.  By default, no headers are generated.

=item help

    --help

Displays the usage message.

=item htmldir

    --htmldir=name

Sets the directory to which all cross references in the resulting
html file will be relative. Not passing this causes all links to be
absolute since this is the value that tells Pod::Html the root of the
documentation tree.

Do not use this and --htmlroot in the same call to pod2html; they are
mutually exclusive.

=item htmlroot

    --htmlroot=name

Sets the base URL for the HTML files.  When cross-references are made,
the HTML root is prepended to the URL.

Do not use this if relative links are desired: use --htmldir instead.

Do not pass both this and --htmldir to pod2html; they are mutually
exclusive.

=item index

    --index
    --noindex

Generate an index at the top of the HTML file.  This is the default
behaviour.

=item infile

    --infile=name

Specify the pod file to convert.  Input is taken from STDIN if no
infile is specified.

=item outfile

    --outfile=name

Specify the HTML file to create.  Output goes to STDOUT if no outfile
is specified.

=item poderrors

    --poderrors
    --nopoderrors

Include a "POD ERRORS" section in the outfile if there were any POD
errors in the infile. This section is included by default.

=item podpath

    --podpath=name:...:name

Specify which subdirectories of the podroot contain pod files whose
HTML converted forms can be linked to in cross references.

=item podroot

    --podroot=name

Specify the base directory for finding library pods. Default is the
current working directory.

=item quiet

    --quiet
    --noquiet

Don't display I<mostly harmless> warning messages.  These messages
will be displayed by default.  But this is not the same as C<verbose>
mode.

=item recurse

    --recurse
    --norecurse

Recurse into subdirectories specified in podpath (default behaviour).

=item title

    --title=title

Specify the title of the resulting HTML file.

=item verbose

    --verbose
    --noverbose

Display progress messages.  By default, they won't be displayed.

=back

=head1 ENVIRONMENT

Uses C<$Config{pod2html}> to setup default options.

=head1 AUTHOR

Marc Green, E<lt>marcgreen@cpan.orgE<gt>.

Original version by Tom Christiansen, E<lt>tchrist@perl.comE<gt>.

=head1 SEE ALSO

L<perlpod>

=head1 COPYRIGHT

This program is distributed under the Artistic License.

=cut

sub new {
    my $class = shift;
    my %args = ();
    $args{Curdir} = File::Spec->curdir;
    $args{Cachedir} = ".";   # The directory to which directory caches
                                #   will be written.
    $args{Dircache} = "pod2htmd.tmp";
    $args{Htmlroot} = "/";   # http-server base directory from which all
                                #   relative paths in $podpath stem.
    $args{Htmldir} = "";     # The directory to which the html pages
                                #   will (eventually) be written.
    $args{Htmlfile} = "";    # write to stdout by default
    $args{Htmlfileurl} = ""; # The url that other files would use to
                                # refer to this file.  This is only used
                                # to make relative urls that point to
                                # other files.

    $args{Poderrors} = 1;
    $args{Podfile} = "";              # read from stdin by default
    $args{Podpath} = [];
    $args{Podroot} = $args{Curdir};         # filesystem base directory from which all
                                #   relative paths in $podpath stem.
    $args{Css} = '';                  # Cascading style sheet
    $args{Recurse} = 1;               # recurse on subdirectories in $podpath.
    $args{Quiet} = 0;                 # not quiet by default
    $args{Verbose} = 0;               # not verbose by default
    $args{Doindex} = 1;               # non-zero if we should generate an index
    $args{Backlink} = 0;              # no backlinks added by default
    $args{Header} = 0;                # produce block header/footer
    $args{Title} = '';                # title to give the pod(s)
    $args{Saved_Cache_Key} = undef;
    return bless \%args, $class;
}

sub process_options {
    my ($self, $opts) = @_;
    if (defined $opts) {
        croak "process_options() needs hashref" unless ref($opts) eq 'HASH';
    }
    else {
        $opts = {};
    }
    # Declare intermediate hash to hold cleaned-up options
    my %h = ();
    @{$h{Podpath}}  = split(":", $opts->{podpath}) if defined $opts->{podpath};
    warn "--libpods is no longer supported" if defined $opts->{libpods};

    $h{Backlink}  =         $opts->{backlink}   if defined $opts->{backlink};
    $h{Cachedir}  = unixify($opts->{cachedir})  if defined $opts->{cachedir};
    $h{Css}       =         $opts->{css}        if defined $opts->{css};
    $h{Header}    =         $opts->{header}     if defined $opts->{header};
    $h{Htmldir}   = unixify($opts->{htmldir})   if defined $opts->{htmldir};
    $h{Htmlroot}  = unixify($opts->{htmlroot})  if defined $opts->{htmlroot};
    $h{Doindex}   =         $opts->{index}      if defined $opts->{index};
    $h{Podfile}   = unixify($opts->{infile})    if defined $opts->{infile};
    $h{Htmlfile}  = unixify($opts->{outfile})   if defined $opts->{outfile};
    $h{Poderrors} =         $opts->{poderrors}  if defined $opts->{poderrors};
    $h{Podroot}   = unixify($opts->{podroot})   if defined $opts->{podroot};
    $h{Quiet}     =         $opts->{quiet}      if defined $opts->{quiet};
    $h{Recurse}   =         $opts->{recurse}    if defined $opts->{recurse};
    $h{Title}     =         $opts->{title}      if defined $opts->{title};
    $h{Verbose}   =         $opts->{verbose}    if defined $opts->{verbose};
    $h{flush}     =         $opts->{flush}      if defined $opts->{flush};

    while (my ($k,$v) = each %h) {
        $self->{$k} = $v;
    };
    return 1;
}

sub cleanup_elements {
    my $self = shift;
    warn "Flushing directory caches\n"
        if $self->{Verbose} && defined $self->{flush};
    $self->{Dircache} = "$self->{Cachedir}/pod2htmd.tmp";
    if (defined $self->{flush}) {
        1 while unlink($self->{Dircache});
    }
    # prevent '//' in urls
    $self->{Htmlroot} = "" if $self->{Htmlroot} eq "/";
    $self->{Htmldir} =~ s#/\z##;
    # Per documentation, Htmlroot and Htmldir cannot both be set to true
    # values.  Die if that is the case.
    my $msg = "htmlroot and htmldir cannot both be set to true values\n";
    $msg .= "Choose one or the other";
    croak $msg if ($self->{Htmlroot} and $self->{Htmldir});


    if (  $self->{Htmlroot} eq ''
       && $self->{Htmldir} ne ''
       && substr( $self->{Htmlfile}, 0, length( $self->{Htmldir} ) ) eq $self->{Htmldir}
       ) {
        # Set the 'base' url for this file, so that we can use it
        # as the location from which to calculate relative links
        # to other files. If this is '', then absolute links will
        # be used throughout.
        # $self->{Htmlfileurl} =
        #   "$self->{Htmldir}/" . substr( $self->{Htmlfile}, length( $self->{Htmldir} ) + 1);
        # Is the above not just "$self->{Htmlfileurl} = $self->{Htmlfile}"?
        $self->{Htmlfileurl} = unixify($self->{Htmlfile});
    }

    # XXX: implement default title generator in pod::simple::xhtml
    # copy the way the old Pod::Html did it
    $self->{Title} = html_escape($self->{Title});
    return 1;
}

sub generate_pages_cache {
    my $self = shift;
    my $cache_tests = $self->get_cache();
    return if $cache_tests;

    # generate %{$self->{Pages}}
    my $pwd = getcwd();
    chdir($self->{Podroot}) ||
        die "$0: error changing to directory $self->{Podroot}: $!\n";

    # find all pod modules/pages in podpath, store in %{$self->{Pages}}
    # - callback used to remove Podroot and extension from each file
    # - laborious to allow '.' in dirnames (e.g., /usr/share/perl/5.14.1)
    my $name2path = Pod::Simple::Search->new->inc(0)->verbose($self->{Verbose})->laborious(1)->recurse($self->{Recurse})->survey(@{$self->{Podpath}});
    foreach my $modname (sort keys %{$name2path}) {
        $self->_save_page($name2path->{$modname}, $modname);
    }

    chdir($pwd) || die "$0: error changing to directory $pwd: $!\n";

    # cache the directory list for later use
    if ($self->{Verbose}) {
        warn "caching directories for later use\n";
    }
    open my $CACHE, '>', $self->{Dircache}
        or die "$0: error open $self->{Dircache} for writing: $!\n";

    my $cacheline = join(":", @{$self->{Podpath}}) . "\n$self->{Podroot}\n";
    print $CACHE $cacheline;
    my $_updirs_only = ($self->{Podroot} =~ /\.\./) && !($self->{Podroot} =~ /[^\.\\\/]/);
    foreach my $key (keys %{$self->{Pages}}) {
        if($_updirs_only) {
          my $_dirlevel = $self->{Podroot};
          while($_dirlevel =~ /\.\./) {
            $_dirlevel =~ s/\.\.//;
            # Assume $self->{Pages}->{$key} has '/' separators (html dir separators).
            $self->{Pages}->{$key} =~ s/^[\w\s\-\.]+\///;
          }
        }
        my $keyline = "$key $self->{Pages}->{$key}\n";
        print $CACHE $keyline;
    }

    close $CACHE or die "error closing $self->{Dircache}: $!";
    return 1;
}

sub prepare_parser {
    my $self = shift;
    my $parser = Pod::Simple::XHTML::LocalPodLinks->new();
    $parser->codes_in_verbatim(0);
    $parser->anchor_items(1); # the old Pod::Html always did
    $parser->backlink($self->{Backlink}); # linkify =head1 directives
    $parser->htmldir($self->{Htmldir});
    $parser->htmlfileurl($self->{Htmlfileurl});
    $parser->htmlroot($self->{Htmlroot});
    $parser->index($self->{Doindex});
    $parser->no_errata_section(!$self->{Poderrors}); # note the inverse
#    $parser->output_string(\my $output); # written to file later
    $parser->pages($self->{Pages});
    $parser->quiet($self->{Quiet});
    $parser->verbose($self->{Verbose});
    return $parser;
}

sub prepare_html_components {
    my ($self, $parser ) = @_;
    $parser->output_string(\my $output); # written to file later
    # We need to add this ourselves because we use our own header, not
    # ::XHTML's header. We need to set $parser->backlink to linkify
    # the =head1 directives
    my $bodyid = $self->{Backlink} ? ' id="_podtop_"' : '';

    my $csslink = '';
    my $tdstyle = ' style="background-color: #cccccc; color: #000"';

    if ($self->{Css}) {
        $csslink = qq(\n<link rel="stylesheet" href="$self->{Css}" type="text/css" />);
        $csslink =~ s,\\,/,g;
        $csslink =~ s,(/.):,$1|,;
        $tdstyle= '';
    }

    # header/footer block
    my $block = $self->{Header} ? <<END_OF_BLOCK : '';
<table border="0" width="100%" cellspacing="0" cellpadding="3">
<tr><td class="_podblock_"$tdstyle valign="middle">
<big><strong><span class="_podblock_">&nbsp;$self->{Title}</span></strong></big>
</td></tr>
</table>
END_OF_BLOCK

    # create own header/footer because of --header
    $parser->html_header(<<"HTMLHEAD");
<?xml version="1.0" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>$self->{Title}</title>$csslink
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<link rev="made" href="mailto:$Config{perladmin}" />
</head>

<body$bodyid>
$block
HTMLHEAD

    $parser->html_footer(<<"HTMLFOOT");
$block
</body>

</html>
HTMLFOOT
    return 1;
}

sub prepare_output {
    my ($self, $parser) = @_;
    my $input;
#    unless (@ARGV && $ARGV[0]) {
        if ($self->{Podfile} and $self->{Podfile} ne '-') {
            $input = $self->{Podfile};
        }
#        else {
#            $input = '-'; # XXX: make a test case for this
#        }
#    } else {
#        $self->{Podfile} = $ARGV[0];
#        $input = *ARGV;
#    }

    warn "Converting input file $self->{Podfile}\n" if $self->{Verbose};
    $parser->output_string(\my $output); # written to file later
    $parser->parse_file($input);
    return $output;
}

sub write_html {
    my ($self, $output) = @_;
    my $FHOUT;
    if($self->{Htmlfile} and $self->{Htmlfile} ne '-') {
        open $FHOUT, ">", $self->{Htmlfile}
            or die "$0: cannot open $self->{Htmlfile} file for output: $!\n";
        binmode $FHOUT, ":utf8";
        print $FHOUT $output;
        close $FHOUT or die "Failed to close $self->{Htmlfile}: $!";
        chmod 0644, $self->{Htmlfile};
    }
    else {
        open $FHOUT, ">-";
        binmode $FHOUT, ":utf8";
        print $FHOUT $output;
        close $FHOUT or die "Failed to close handle to STDOUT: $!";
    }
    return 1;
}

sub pod2html {
    local @ARGV = @_;
    my $options = parse_command_line();

    my $p2h = Pod::Html->new();
    $p2h->process_options( $options );
    $p2h->cleanup_elements();
    $p2h->generate_pages_cache();

    my $parser = $p2h->prepare_parser();
    $p2h->prepare_html_components($parser);
    my $output = $p2h->prepare_output($parser);
    my $rv = $p2h->write_html($output);
    return $rv;
}

sub get_cache {
    my $self = shift;
#    my @cache_key_args = @_;

    # A first-level cache:
    # Don't bother reading the cache files if they still apply
    # and haven't changed since we last read them.

    my $this_cache_key = $self->cache_key();
    return 1 if $self->{Saved_Cache_Key}
        and $this_cache_key eq $self->{Saved_Cache_Key};
    $self->{Saved_Cache_Key} = $this_cache_key;

    # load the cache of %Pages if possible.  $tests will be
    # non-zero if successful.
    my $tests = 0;
    if (-f $self->{Dircache}) {
        warn "scanning for directory cache\n" if $self->{Verbose};
        $tests = $self->load_cache();
    }

    return $tests;
}

sub cache_key {
    my $self = shift;
    return join('!' => (
        $self->{Dircache},
        $self->{Recurse},
        @{$self->{Podpath}},
        $self->{Podroot},
        stat($self->{Dircache}),
    ) );
}

#
# load_cache - tries to find if the cache stored in $dircache is a valid
#  cache of %Pages.  if so, it loads them and returns a non-zero value.
#
sub load_cache {
    my $self = shift;
    my $tests = 0;
    local $_;

    warn "scanning for directory cache\n" if $self->{Verbose};
    open(my $CACHEFH, '<', $self->{Dircache}) ||
        die "$0: error opening $self->{Dircache} for reading: $!\n";
    $/ = "\n";

    # is it the same podpath?
    $_ = <$CACHEFH>;
    chomp($_);
    $tests++ if (join(":", @{$self->{Podpath}}) eq $_);

    # is it the same podroot?
    $_ = <$CACHEFH>;
    chomp($_);
    $tests++ if ($self->{Podroot} eq $_);

    # load the cache if its good
    if ($tests != 2) {
        close($CACHEFH);
        return 0;
    }

    warn "loading directory cache\n" if $self->{Verbose};
    while (<$CACHEFH>) {
        /(.*?) (.*)$/;
        $self->{Pages}->{$1} = $2;
    }

    close($CACHEFH);
    return 1;
}


#
# store POD files in %Pages
#
sub _save_page {
    my ($self, $modspec, $modname) = @_;

    # Remove Podroot from path
    $modspec = $self->{Podroot} eq File::Spec->curdir
               ? File::Spec->abs2rel($modspec)
               : File::Spec->abs2rel($modspec,
                                     File::Spec->canonpath($self->{Podroot}));

    # Convert path to unix style path
    $modspec = unixify($modspec);

    my ($file, $dir) = fileparse($modspec, qr/\.[^.]*/); # strip .ext
    $self->{Pages}->{$modname} = $dir.$file;
}

package Pod::Simple::XHTML::LocalPodLinks;
use strict;
use warnings;
use parent 'Pod::Simple::XHTML';

use File::Spec;
use File::Spec::Unix;
use lib ( './lib' );
use Pod::Html::Auxiliary qw(
    unixify
    relativize_url
);

__PACKAGE__->_accessorize(
 'htmldir',
 'htmlfileurl',
 'htmlroot',
 'pages', # Page name => relative/path/to/page from root POD dir
 'quiet',
 'verbose',
);

# Subclass Pod::Simple::XHTML::resolve_pod_page_link()
sub resolve_pod_page_link {
    my ($self, $to, $section) = @_;

    return undef unless defined $to || defined $section;
    if (defined $section) {
        $section = '#' . $self->idify($section, 1);
        return $section unless defined $to;
    } else {
        $section = '';
    }

    my $path; # path to $to according to %Pages
    unless (exists $self->pages->{$to}) {
print STDERR "AAA: In the unless block\n";
        # Try to find a POD that ends with $to and use that.
        # e.g., given L<XHTML>, if there is no $Podpath/XHTML in %Pages,
        # look for $Podpath/*/XHTML in %Pages, with * being any path,
        # as a substitute (e.g., $Podpath/Pod/Simple/XHTML)
        my @matches;
        foreach my $modname (keys %{$self->pages}) {
            push @matches, $modname if $modname =~ /::\Q$to\E\z/;
        }
print STDERR "BBB: matches: <@matches>\n";

        if ($#matches == -1) {
            warn "Cannot find \"$to\" in podpath: " .
                 "cannot find suitable replacement path, cannot resolve link\n"
                 unless $self->quiet;
            return '';
        } elsif ($#matches == 0) {
            warn "Cannot find \"$to\" in podpath: " .
                 "using $matches[0] as replacement path to $to\n"
                 unless $self->quiet;
            $path = $self->pages->{$matches[0]};
        } else {
            warn "Cannot find \"$to\" in podpath: " .
                 "more than one possible replacement path to $to, " .
                 "using $matches[-1]\n" unless $self->quiet;
            # Use [-1] so newer (higher numbered) perl PODs are used
            $path = $self->pages->{$matches[-1]};
        }
    } else {
print STDERR "CCC: In the else block\n";
        $path = $self->pages->{$to};
    }

    my $url = File::Spec::Unix->catfile(unixify($self->htmlroot),
                                        $path);

    if ($self->htmlfileurl ne '') {
print STDERR "DDD: In the ne block\n";
        # then $self->htmlroot eq '' (by definition of htmlfileurl) so
        # $self->htmldir needs to be prepended to link to get the absolute path
        # that will be relativized
        $url = relativize_url(
            File::Spec::Unix->catdir(unixify($self->htmldir), $url),
            $self->htmlfileurl # already unixified
        );
    }

print STDERR "EEE: Returning: ", $url . ".html$section", "\n";
    return $url . ".html$section";
}

1;
