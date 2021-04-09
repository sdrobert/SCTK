#! /usr/bin/env perl
#
#  File:  csrfilt.sh
#  Date:  April 9, 2021
#  Usage: csrfilt.pl global-map-file [ utterance-map-file ] < infile > outfile
#         Filter the input for stdin, and write the output to stdout
#
#  Desc:  This filter is used to "pre-filter" .lsn hypothesis and
#          reference transcriptions to apply a set of word-mapping rules
#          prior to scoring.  The word-mapping rules permit the
#          elimination of ambiguous lexical representations.  The
#          filter applies the rules located in two word map files to the
#          transcriptions.  The first word map file, "glYYMMDD.map",
#          applies a set of rules globally to all transcriptions.  The
#          second, "utYYMMDD.map", applies particular rules to particular
#          utterances.  The two .map files are named so as to indicated
#          the last date they were updated.
#
#  Version 1.0 Feb 1, 1993
#  Version 1.1 Sep. 21, 1995
#       JGF added the option to automatically split hyphenated words
#       JGF added the option to interpret ctm files appropriately
#  Version 1.2 Oct. 20, 1995
#       JGF added the ability to pass through comments un-scathed
#       JGF changed the uppercase conversion to not effect comment lines
#  Version 1.3 Jan 17, 1996
#       JGF forced the script to add spaces to the end and beginning of each non-comment
#           line before processing.  After processing, the spaces are deleted
#  Version 1.4 Nov 24, 1996
#       WMF replaced rfilter1 with a new version which runs faster, and can handle
#           context sensitive rules
#       JGF added a new input format STM
#       JGF Made the glm file sensitive to the input type by using the notation:
#           ;;  INPUT_DEPENDENT_APPLICATION = "<REGEXP>"
#           anywhere in the glm file.  The <REGEXP> tag is a perl regular
#           expression which is matched against the input type via the
#           '-i' option.
#  Version 1.5 Aug 4, 1997
#       JGF added the "-i trn" option
#       JGF modified all exit codes to be 0 on successful, completion 1 otherwise
#  Version 1.6
#       JGF made the utterance-map-file optional. . . finally
#       JGF add the -s option
#  Version 1.7
#       JGF added the -e option to tell set the code to extended ascii
#  Version 1.8 Released around April 1998
#       JGF add the -i txt option
#  Version 1.9 Released Sept 8. 1998
#       JGF added filtering step to rfilter1 to use optionally deletable parens
#       JGF removed a missed usage of sed!!!
#  Version 1.10
#       JGF Added rttm input type
#  Version 1.11
#       JGF Removed the use of EXE_DIR.  All utilities are expected in the path
#  Version 1.12
#       JGF Rewrote the delete hypen processor
#  Version 1.13
#       JGF Fixed hyphen processor, fragment markers were deleted!
#  Version 1.14 Apr 21, 2006
#       JA  Update the rttm filtering to accept the asclite specifications
#       JGF Fix the -dh option for rttm
#  Version 1.15 Feb 9, 2007
#       JGF Added the data purpose field so that the filtering can be contolled
#           based on if the texts are references ot hyps
#  Version 1.16 Apr 30, 2009
#       JGF Redesigned the code to no upcase everything, instead just the transcript
#       JGF Fixed bug with delete hypthens on opt del words
#  Version 1.17 Sep 15, 2010
#       JGF - Fixed the trn preprocessor to pass through comment lines without filtering
#  Version 1.18 Apr 9, 2021
#       SDR Rewrote in Perl. Added an option to specify the location of
#       rfilter1

use warnings;
use strict;

use POSIX ":sys_wait_h";
use Getopt::Long;
use File::Temp qw/ :seekable /;
use File::Spec;

my $Version="1.18";

my $usage = "Usage: $0 <OPTIONS> global-map-file [ utterance-map-file ] < infile > outfile\n".
"Version: $Version\n".
"\n".
"Desc: csrfilt.pl applies a set of text transformation rules contained in\n".
"      'global-map-file' and the optional 'utterance-map-file' to the input\n".
"      text.  The text input is read from stdin and the modified text goes \n".
"      to stdout.\n".
"      The file 'rules.doc' within the distribution directory describes the\n".
"      rule file format.\n".
"\n".
"OPTIONS:\n".
"    -dh     ->  replaces hyphens with spaces in hyphenated words\n".
"    -i ctm  ->  set the input type to ctm. If a word from a ctm file is\n".
"                split, the script divides the original word's duration among\n".
"                its constituents.\n".
"    -i stm  ->  sets the input type to stm. This forces the mapping rules to\n".
"                apply to the text field only.\n".
"    -i trn  ->  sets the input type to trn. This forces the mapping rules to\n".
"                apply to the text portion of the trn record.  (Default)\n".
"    -i txt  ->  sets the input type to txt, no formatting, all words are\n".
"                fair game.\n".
"    -i rttm ->  sets the input type to rttm.\n".
"    -s      ->  do not up-case everything\n".
"    -e      ->  textual data is extended ASCII\n".
"    -t [ref|hyp] -> sets the input type either reference data or hyp data so\n".
"                that the rule-sets within the GLM can be activated\n".
"    -r <path> -> Path to rfilter1 executable. If unset, will assumed to be\n".
"                 on the path";

my $DeleteHyphens = "";
my $UpCase = "true";
my $ExtASCII = "";
my $InputType = "trn";
my $DataPurpose = "";
my $rfilter = "rfilter1";

GetOptions(
  "dh" => \$DeleteHyphens,
  "s"  => sub { $UpCase = ""; },
  "e" => \$ExtASCII,
  "i=s" => sub {
    my ($opt_name, $opt_value) = @_;
    $opt_value =~ tr/A-Z/a-z/;
    die "Error: -$opt_name option requires either \"ctm\", \"stm\", \"txt\", \"trn\", or \"rttm\", not $opt_value"
      unless ($opt_value =~ /^(ctm|stm|trn|txt|rttm)$/);
    $InputType = $opt_value;
  },
  "t=s" => sub {
    my ($opt_name, $opt_value) = @_;
    $opt_value =~ tr/A-Z/a-z/;
    die "Error: -$opt_name option requires either \"ref\" or \"hyp\", not $opt_value"
      unless ($opt_value =~ /^(ref|hyp)$/);
    $DataPurpose = $opt_value;
  },
  "r=s" => sub {
    my ($opt_name, $opt_value) = @_;
    die "Error: -$opt_name option expects a path to an executable, got $opt_value"
      unless (-x $opt_value);
    $rfilter = File::Spec->canonpath($opt_value);
  }
) or die $usage;

die $usage unless (@ARGV == 1 or @ARGV == 2);

my $glob_map = shift @ARGV;
unless (-r $glob_map) {
  die "$glob_map is not a readable file!\n$usage";
}

# utt_map and ut_rfilt might be remnants of an older version of the
# code (they were used in an unreachable else block). For
# compatibility's sake, we won't *stop* the possibility of a second
# argument, but we don't actually do anything with this argument
my $utt_map = "";
if (@ARGV == 1) {
  $utt_map = shift @ARGV;
  unless (-r $utt_map) {
    die "$utt_map is not a readable file!\n$usage";
  }
}

# capture and clean up the input
my $hs_filt_orig = new File::Temp();
while (<>) {
  if ($_ !~ /^;;/) {
  	s/^/ /; s/$/ /; s/[ \t]+/ /g;
  }
  print $hs_filt_orig $_;
}
$hs_filt_orig->seek(0, SEEK_SET);

# automatically modify the global mapping file to only include regions
# which apply to the input type.
my $hs_filt_glm = new File::Temp ();
$hs_filt_glm->autoflush(1);
open(my $GLM, "<", $glob_map) or die "Cannot open $glob_map";
my $applies = 1;
while (<$GLM>) {
  # made InputType and DataPurpose lowercase when processing opts
  if ($_ =~ /^;;\s+INPUT_DEPENDENT_APPLICATION\s*=\s*\"([^\"]*)\"/){
    (my $exp = $1) =~ tr/A-Z/a-z/;
    $applies = 0;
    if ($InputType =~ /$exp/){ $applies = 1; }
    if ($DataPurpose =~ /$exp/){ $applies = 1; }
  }
  if ($applies == 1) { print $hs_filt_glm $_; }
}
close($GLM);
close($hs_filt_glm);

# perform the filter on the utterance specific rules
my $hs_filt_outext = new File::Temp();
my $hs_filt_out = new File::Temp();

if ($InputType eq "ctm") {
  while (<$hs_filt_orig>) {
    if ($_ =~ /^;;/) {
      print $hs_filt_outext $_;
      print $hs_filt_out "\n";
    } else {
      my @a = split(/\s+/, $_);
      print $hs_filt_out splice(@a,5,1)."\n";
      print $hs_filt_outext join(" ",@a)."\n";
    }
  }
} elsif ($InputType eq "rttm") {
  while(<$hs_filt_orig>){
    if ($_ !~ /^ LEXEME.* (lex|fp|un-lex|for-lex|alpha|acronym|interjection|propernoun|other) /) {
      print $hs_filt_outext $_;
      print $hs_filt_out "\n";
    } else {
      my @a = split(/\s+/, $_);
      print $hs_filt_out splice(@a,6,1)."\n";
      print $hs_filt_outext join(" ",@a)."\n";
    }
  }
} elsif ($InputType eq "stm") {
  while(<$hs_filt_orig>){
    if ($_ =~ /^;;/) {
      print $hs_filt_outext $_;
      print $hs_filt_out "\n";
    } elsif ($_ =~ /^(\s*\S+\s*\S+\s*\S+\s*\S+\s*\S+\s*<\S+>)(.*)$/){
      print $hs_filt_outext $1."\n";
      print $hs_filt_out $2."\n";
    } elsif ($_ =~ /^(\s*\S+\s*\S+\s*\S+\s*\S+\s*\S+)(.*)$/){
      print $hs_filt_outext $1."\n";
      print $hs_filt_out $2."\n";
    } else {
      die("Error: Parse of stm line failed");
    }
  }
} elsif ($InputType eq "trn") {
  while(<$hs_filt_orig>){
    if ($_ =~ /^;;/) {
      print $hs_filt_outext $_;
      print $hs_filt_out "\n";
    } elsif ($_ =~ /^(.*)(\(.*\))\s*$/){
      print $hs_filt_out $1."\n";
      print $hs_filt_outext $2."\n";
    } else {
      die("Error: Parse of trn line failed");
    }
  }
} else {  # txt
  while(<$hs_filt_orig>){
    if ($_ =~ /^;;/) {
      print $hs_filt_outext $_;
      print $hs_filt_out "\n";
    } else {
      print $hs_filt_outext "\n";
      print $hs_filt_out $_;
    }
  }
}
close($hs_filt_orig);
$hs_filt_out->seek(0, SEEK_SET);
$hs_filt_outext->seek(0, SEEK_SET);


# We create a new file and immediately close it. We're more interested in the
# location/cleanup than the file itself. We're going to have a child process
# write to this file location, wait for it to finish, then read it. It's not
# as efficient as chaining pipes, but it should be portable.
my $hs_rfilt_out_ = new File::Temp();
close($hs_rfilt_out_);

my @invalid_tags = qw();
open(my $hs_rfilt_in, "|-", "$rfilter $hs_filt_glm > $hs_rfilt_out_")
  or die "Could not open rfilter1 pipe!";
local $SIG{PIPE} = sub { die "rfilter1 pipe broke" };

while (<$hs_filt_out>) {
  s/\(/( /g;
  s/\)/ )/g;
  s/^/ /;
  s/$/ /;
  my $line = $_;
  s/\(/   \(/g; s/\)/\)  /; s/\s\([^\(\)]+\)//g;
  if ($_ =~ /[()]/) { push(@invalid_tags, $_); }
  unless (@invalid_tags) {
    $_ = $line;

    # toUpper
    if ($_ !~ /^;;/) {
      if ($UpCase) {
        tr/a-z/A-Z/;
        if ($ExtASCII) {
          tr/\340-\377/\300-\337/;
        }
      }
    }

    print $hs_rfilt_in $_;
  }
}
close($hs_filt_out);
close($hs_rfilt_in);
die $! if $? != 0;

if (@invalid_tags) {
  # FIXME(sdrobert): this should really be sent to stderr along with the die,
  # but I want to prove compatibility with the shell script first.
  $_ = join "", @invalid_tags;
  print "Error: Can not filter text with illegally formatted optional deletion tags.  Look for:\n$_";
  die;
}

sub final_filt {
  if ($_ !~ /^;/) {
    s/^[ \t]+//;
    s/[ \t]+$//;
    s/[ \t]+/ /g;
  }
}

open(my $hs_rfilt_out, "<", $hs_rfilt_out_->filename);
my $word = "";
while (<$hs_rfilt_out>) {

  # deleteHyphens
  s/([^\( ])-(?=[^\) ])/$1 /g if ($DeleteHyphens);

  # propagateOptDel
  while ($_ =~ s/(\(\s+[^()\s]+\s+)([^()\s]+)/$1\) \( $2/) {}

  s/^ //;
  s/ $//;
  s/\(\s+/(/g;
  s/\s+\)/)/g;

  {
    my $text = $_;
    my $ext = <$hs_filt_outext>;
    if ($InputType eq "ctm") {
      chomp($text);
      if ($text) {
        my @a = split(/\s+/,$ext);
        splice(@a, 5, 0, $text);
        $ext = join(" ",@a)."\n";
      }
      $_ = $ext;

      # hs_filt_ctm
      # N.B. note final_filt came immediately after this file in csrfilt.sh,
      # but here we just modify it before printing so that we don't have to
      # deal with another temporary file.
      if ($_ =~ /^;;/) {
        final_filt;
        print;
      } else {
      	s/^\s+//;
	      s/([{}])/ $1 /g;
	      my @l = split;
	      if ($#l == 4) {
          final_filt;
          print;
        } else {
          my $limit;
          my $conf;
	        if ($l[$#l] =~ /^[0-9\.-]*$/) {
            $limit=$#l-1;
            $conf=$l[$#l];
          } else {
            $limit=$#l;
            $conf="";
          }
          my $data = join(" ",splice(@l,4,$limit - 4 + 1));
	        my @sets = split(/\//,$data);
	        if ($#sets > 0) {
		        $_ = sprintf("%s %s * * %s <ALT_BEGIN>\n",$l[0],$l[1],$word);
            final_filt;
            print;
	        }
	        for (my $sn = 0; $sn <= $#sets; $sn++) {
		        my $set = $sets[$sn];
		        $set =~ s/[{}]//g;
		        $set =~ s/^\s+//;
		        my @words = split(/\s+/,$set);
		        my $dur = $l[3] / ($#words + 1);
		        my $i=0;
            foreach $word(@words) {
              $_ = sprintf("%s %s %.3f %.3f %s %s\n",$l[0],$l[1],$l[2]+($dur * $i),$dur,$word,$conf);
              final_filt;
              print;
              $i++;
            }
            if ($#sets > 0 && $sn != $#sets){
              $_ = sprintf("%s %s * * %s <ALT>\n",$l[0],$l[1],$word);
              final_filt;
              print;
            }
	        }
	        if ($#sets > 0) {
		        $_ = sprintf("%s %s * * %s <ALT_END>\n",$l[0],$l[1],$word);
            final_filt;
            print;
    	    }
	      }
      }
    } elsif ($InputType eq "rttm") {
      chomp($text);
      if ($text =~ /\s/){
        $text =~ s/([\{\}\/\@])/ $1 /g;
        $text =~ s/\s+/ /g;
        $text =~ s/^\s//;
        $text =~ s/\s$//;
        $text =~ s/\s/_/g;
      }
      if ($text) {
        my @a = split(/\s+/,$ext);
        splice(@a, 6, 0, $text);
        $ext = join(" ",@a)."\n";
      }
      $_ = $ext;
      final_filt;
      print;
    } elsif ($InputType eq "stm") {
      chop($ext);
      $_ = "$ext$text";
      final_filt;
      print;
    } elsif ($InputType eq "trn") {
      chomp($text);
      $_ = "$text$ext";
      final_filt;
      print;
    } else {  # txt
      $_ = $text;
      final_filt;
      print;
    }
  }
}
close($hs_rfilt_out);
close($hs_filt_outext);