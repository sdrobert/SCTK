#! /usr/bin/env perl
use warnings;
use strict;

use Config;
use Getopt::Long;
use File::Temp;
use File::Spec;
use File::Basename;
use File::Compare qw(compare_text);

my $usage = "Usage: $0 [<OPTIONS>]

OPTIONS
  -o <dir>:  Store results in desired folder instead of a temporary one.
  -i <dir>:  Directory where expected value files exist
  -w:        Write expected values instead of comparing
";

my $outdir;
my $indir = ".";
my $perl = $Config{perlpath};
my $set_test = 0;

GetOptions(
  "o=s" => sub {
    my ($opt_name, $opt_value) = @_;
    die "Error -$opt_name expected directory name, got $opt_value"
      unless (-d $opt_value || mkdir($opt_value));
    $outdir = File::Spec->canonpath($opt_value);
  },
  "i=s" => sub {
    my ($opt_name, $opt_value) = @_;
    die "Error -$opt_name expected existing directory, got $opt_value"
      unless (-d $opt_value);
    $indir = File::Spec->canonpath($opt_value);
  },
  "w" => \$set_test
) or die "$usage";

unless (defined($outdir)) {
  $outdir = File::Temp->newdir();
}

sub run_test {
  my ($name, $cmd, $exp) = @_;
  print "   Beginning $name\n";
  $exp = File::Spec->catfile($indir, $exp);
  my $act = $set_test ? $exp : File::Spec->catfile($outdir, basename($exp).".act");
  open(my $act_fh, '>', $act);
  print $act_fh `$cmd`;
  close($act_fh);
  unless ($set_test) {
    # first have to filter out lines that contain RTTMValidator
    my $tmp = new File::Temp();
    close($tmp);
    system "$perl -ne \"print unless /RTTMValidator/;\" < $exp > $tmp";
    if (compare_text($tmp->filename, $act)) {
      print "   $name failed\n";
      system "diff", $tmp->filename, $act;
      die;
    } else {
      print "   $name passed\n";
    }
  } else {
    print "   Wrote $name to $act\n";
  }
}

my $prefix = "$perl rttmValidator.pl -S -t";

for (my $i = 1; $i < 37; ++$i) {
  my $tn = sprintf("test%02d", $i);
  if (-f "$indir/$tn.rttm" && -f "$indir/$tn.log.saved") {
    if (-f "$indir/$tn.rttm.toskip") {
      print "   $tn skipped\n";
    } else {
      run_test("$tn", "$prefix -i $indir/$tn.rttm | $perl -ne \"print unless /RTTMValidator/;\"", "$tn.log.saved");
    }
  }
}
