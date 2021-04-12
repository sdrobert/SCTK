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
";

my $outdir;
my $indir = ".";
my $perl = $Config{perlpath};

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
  }
) or die "$usage";

unless (defined($outdir)) {
  $outdir = File::Temp->newdir();
}

sub run_test {
  my ($name, $cmd, $exp) = @_;
  print "Beginning $name\n";
  $exp = File::Spec->catfile($indir, $exp);
  my $act = File::Spec->catfile($outdir, basename($exp).".act");
  open(my $act_fh, '>', $act);
  print $act_fh `$cmd`;
  # die "$name error: $!" if $?;
  close($act_fh);
  if (compare_text($exp, $act)) {
    print "$name failed\n";
    system "diff", $exp, $act;
    die;
  } else {
    print "$name passed\n";
  }
}

my $prefix = "$perl stmValidator.pl";

for (my $i = 1; $i < 37; ++$i) {
  my $tn = sprintf("test%02d", $i);
  if (-f "$indir/$tn.stm" && -f "$indir/$tn.log.saved") {
    if (-f "$indir/$tn.stm.toskip") {
      print "$tn skipped\n";
    } else {
      run_test("$tn", "$prefix -i $indir/$tn.stm | perl -pe \"s/^Validated .*$tn\.stm/Validated $tn.stm/\"", "$tn.log.saved");
    }
  }
}
