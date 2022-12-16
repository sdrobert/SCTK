#! /usr/bin/env perl
use warnings;
use strict;

use Cwd;
use Config;
use Getopt::Long;
use File::Temp;
use File::Spec;
use File::Copy;
use File::Path qw(remove_tree);
use File::Basename;
use File::Compare qw(compare_text);

my $usage = "Usage: $0 [<OPTIONS>]

OPTIONS
  -o <dir>:  Store results in desired folder instead of a temporary one.
  -i <dir>:  Directory where expected value files exist
  -s <path>: Path to sc_stats executable
";

my $has_diff = "";
my $has_slm = "";
my $outdir;
my $indir = ".";
my $sc_stats = "sc_stats";
my $scl_flags = "";
my $perl = $Config{perlpath};
my $cat;
if ("$^O" =~ /Win/) {
    $cat = "type";
} else {
    $cat = "cat";
}

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
  "s=s" => sub {
    my ($opt_name, $opt_value) = @_;
    die "Error -$opt_name expected existing exectuable, got $opt_value"
      unless (-x $opt_value);
    $sc_stats = File::Spec->canonpath($opt_value);
  },
) or die "$usage";

unless (defined($outdir)) {
  $outdir = File::Temp->newdir();
}

# some tests require this
chdir($indir) or die "Could not move to directory $indir";

sub compare_files {
  # tsc_stats.sh applies the following options in its diff command:
  # -x CVS: exclude any base names matching "CVS" (this is actually done by a
  #         grep on the diff, but I'm assuming it's for the same purpose)
  # In addition, we filter out the line "Output written to..."
  # because we're probably not writing there :/
  my ($test_id, $relative_path, $exp_root, $act_root) = @_;
  # the -x stuff
  return 1 if ($relative_path =~ /^(|.*\/)(CVS)(\/.*|)$/);
  my $filtered_exp = File::Temp->new();
  my $filtered_act = File::Temp->new();
  open(my $unfiltered_exp, "<", "$exp_root/$relative_path")
    or die "$test_id failed: unable to open $exp_root/$relative_path";
  while (<$unfiltered_exp>) {
    next if /Output written to/;
    print $filtered_exp $_;
  }
  close($unfiltered_exp);
  close($filtered_exp);
  open(my $unfiltered_act, "<", "$act_root/$relative_path")
    or die "$test_id failed: unable to open $act_root/$relative_path";
  while (<$unfiltered_act>) {
    next if /Output written to/;
    print $filtered_act $_;
  }
  close($unfiltered_act);
  close($filtered_act);
  if (compare_text($filtered_exp->filename, $filtered_act->filename)) {
    print "$test_id failed: diff {$exp_root,$act_root}/$relative_path below\n";
    system "diff", $filtered_exp->filename, $filtered_act->filename;
    die;
  }
  return 1;
}

sub compare_directories {
  my ($test_id, $relative_path, $exp_root, $act_root) = @_;
  opendir(my $dh, "$exp_root/$relative_path")
    or die "$test_id error: could not open $exp_root/$relative_path as a directory";
  my @fns = readdir $dh;
  closedir($dh);
  foreach my $fn (@fns) {
    next unless ($fn =~ /^$test_id\..*$/);
    my $new_relative = join("/", $relative_path, $fn);
    die unless (-d "$exp_root/$new_relative" || compare_files($test_id, $new_relative, $exp_root, $act_root));
    die unless (-f "$exp_root/$new_relative" || compare_directories($test_id, $new_relative, $exp_root, $act_root));
  }
  opendir($dh, "$act_root/$relative_path")
    or die "$test_id error: could not open $exp_root/$relative_path as a directory";
  @fns = readdir $dh;
  closedir($dh);
  foreach my $fn (@fns) {
    next unless ($fn =~ /^$test_id.*$/);
    my $new_relative = join("/", $relative_path, $fn);
    die unless (-f "$act_root/$new_relative" || compare_directories($test_id, $new_relative, $exp_root, $act_root));
    die unless (-d "$act_root/$new_relative" || compare_files($test_id, $new_relative, $exp_root, $act_root));
  }
  return 1;
}

sub run_test {
  my ($name, $desc, $cmd, $req) = @_;
  print "Beginning $name: $desc\n";
  if (defined($req)) {
    if ($req eq "SLM" && not($has_slm)) {
      print "            **** SLM weighted alignment is disabled, not testing ***\n";
      return 0;
    }
    if ($req eq "DIFF" && not($has_diff)) {
      print "            **** Diff alignments have been disabled, not testing ***\n";
      return 0;
    }
  }
  my $act_dir = File::Spec->catfile($outdir, $name);
  if (-d $act_dir) {
    remove_tree($act_dir, {
      safe => 1,
      keep_root => 1
    }) or die "Error $name: Could not clear $act_dir";
  } else {
    mkdir($act_dir) or die "Error $name: Could not create directory $act_dir: $!";
  }

  $cmd .=
    " -n $act_dir/$name".
    " 1> ".File::Spec->catfile($act_dir, "$name.out").
    " 2> ".File::Spec->catfile($act_dir, "$name.err");

  system($cmd) == 0
    or die "$name failed: exit code $?";

  compare_directories($name, ".", "base_sc_stats", $act_dir) or die;
}

unless (-d "$outdir") {
  mkdir $outdir or die "Could not make directory";
}

my $infix = "$sc_stats -p -t mapsswe -v";

run_test(
  "test1a",
  "Symmetric tests on MAPSSWE (1 then 2)",
  "$cat file1.sgml file2.sgml | $infix"
);

run_test(
  "test1b",
  "Symmetric tests on MAPSSWE (2 then 1)",
  "$cat file2.sgml file1.sgml | $infix"
);