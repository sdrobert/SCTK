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

my $prefix = "$perl ctmValidator.pl";

run_test("test00", "$prefix -i $indir/test00.ctm | $perl -pe \"s/Validation '[^']+/Validation 'test00.ctm/\"", "test00.log.saved");
