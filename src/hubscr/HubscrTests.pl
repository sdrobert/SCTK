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
  -o <dir>:             Store results in desired folder instead of a temporary one.
  -i <dir>:             Directory where files exist
  -e <dir>:             Directory where expected value files exist
  -p <dir>[<dir>,...]:  Paths to search for other scripts
";

my $outdir;
my $expdir = ".";
my $indir = ".";
my $perl = $Config{perlpath};
my $base = getcwd();
my $paths = $base;
$SIG{TERM} = sub {chdir $base;};

GetOptions(
  "o=s" => sub {
    my ($opt_name, $opt_value) = @_;
    die "Error -$opt_name expected directory name, got $opt_value"
      unless (-d $opt_value || mkdir($opt_value));
    $outdir = File::Spec->rel2abs($opt_value);
  },
  "e=s" => sub {
    my ($opt_name, $opt_value) = @_;
    die "Error -$opt_name expected existing directory, got $opt_value"
      unless (-d $opt_value);
    $expdir = File::Spec->rel2abs($opt_value);
  },
  "i=s" => sub {
    my ($opt_name, $opt_value) = @_;
    die "Error -$opt_name expected existing directory, got $opt_value"
      unless (-d $opt_value);
    $indir = File::Spec->rel2abs($opt_value);
  },
  "p=s" => sub {
    my ($opt_name, $opt_value) = @_;
    my @p = ();
    foreach (split(/,/, $opt_value)) {
      die "Error -$opt_name expected list of existing directories, but got $_"
        unless (-d $_);
      push(@p, File::Spec->rel2abs($_));
    }
    $paths = join($Config::Config{path_sep}, @p);
  }
) or die "$usage";

unless (defined($outdir)) {
  $outdir = File::Temp->newdir();
}

sub compare_files {
  # RunTests.pl applies the following options in its diff command:
  # -i: ignore case
  # -x CVS: exclude any base names matching "CVS"
  # -x .DS_Store: exclude any base names containing ".DS_Store"
  # -x *lur: exclude any base names ending with "lur"
  # -x log: exclude any base names matchiing "log"
  #    Note: we don't exclude these earlier on, so we have to check if any
  #    path in the split matches these
  # -I '[cC]reation[ _]date'
  # -I 'md-eval'
  #    Exclude any lines from the diff matching these expressions
  my ($test_id, $relative_path, $exp_root, $act_root) = @_;
  # the -x stuff
  return 1 if ($relative_path =~ /^(|.*\/)(CVS|\.DS_Store|.*lur|log)(\/.*|)$/);
  my $filtered_exp = File::Temp->new();
  my $filtered_act = File::Temp->new();
  open(my $unfiltered_exp, "<", "$exp_root/$relative_path")
    or die "$test_id failed: unable to open $exp_root/$relative_path";
  while (<$unfiltered_exp>) {
    # the -I stuff
    next if /[cC]reation[ _]date/;
    next if /md-eval/;
    tr:A-Z:a-z:;  # not sure how much more diff -i does than this
    print $filtered_exp $_;
  }
  close($unfiltered_exp);
  close($filtered_exp);
  open(my $unfiltered_act, "<", "$act_root/$relative_path")
    or die "$test_id failed: unable to open $act_root/$relative_path";
  while (<$unfiltered_act>) {
    next if /[cC]reation[ _]date/;
    next if /md-eval/;
    tr:A-Z:a-z:;
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
    next if ($fn =~ /^\.+$/);
    my $new_relative = join("/", $relative_path, $fn);
    die unless (-d "$exp_root/$new_relative" || compare_files($test_id, $new_relative, $exp_root, $act_root));
    die unless (-f "$exp_root/$new_relative" || compare_directories($test_id, $new_relative, $exp_root, $act_root));
  }
  opendir($dh, "$act_root/$relative_path")
    or die "$test_id error: could not open $exp_root/$relative_path as a directory";
  @fns = readdir $dh;
  closedir($dh);
  foreach my $fn (@fns) {
    next if ($fn =~ /^\.+$/);
    my $new_relative = join("/", $relative_path, $fn);
    die unless (-f "$act_root/$new_relative" || compare_directories($test_id, $new_relative, $exp_root, $act_root));
    die unless (-d "$act_root/$new_relative" || compare_files($test_id, $new_relative, $exp_root, $act_root));
  }
  return 1;
}

sub run_test {
  my ($name, $cmd, $glm, $ref, $exp, @systems) = @_;
  print "Beginning $name\n";
  my $act_dir = File::Spec->catfile($outdir, basename($exp.".act"));
  if (-d $act_dir) {
    remove_tree($act_dir, {
      safe => 1,
      keep_root => 1
    }) or die "Error $name: Could not clear $act_dir";
  } else {
    mkdir($act_dir) or die "Error $name: Could not create directory $act_dir: $!";
  }
  chdir($act_dir) or die "Error $name: Could not move to directory $act_dir";
  my $rel_glm = basename($glm);
  copy($glm, $rel_glm) or die "Error $name: Could not copy $glm to $act_dir/$rel_glm: $!";
  my $rel_ref = basename($ref);
  copy($ref, $rel_ref) or die "Error $name: Could not copy $ref to $act_dir/$rel_ref: $!";
  my @rel_systems;
  foreach my $fp (@systems) {
    my $bn = basename($fp);
    copy($fp, $bn) or die "Error $name: Could not copy $fp to $act_dir/$bn";
    push(@rel_systems,$bn);
  }
  my $rel_systems_ = join(" ", @rel_systems);
  $cmd .= " -g $rel_glm -r $rel_ref $rel_systems_ > log";
  system($cmd) == 0
    or die "$name failed: error code $?";
  compare_directories($name, ".", $exp, $act_dir) or die;
}

my $prefix = "$perl $base/hubscr.pl -p $paths";
unless (-d "$outdir") {
  mkdir $outdir or die "Could not make directory";
}

# we make this an eval block so we can move out of the temp
# directory
eval {
  # run_test(
  #   "test1-sastt",
  #   "$prefix -G -f rttm -F rttm -a -l english -h sastt",
  #   "$indir/example.glm",
  #   "$indir/sastt-case1.ref.rttm",
  #   "$expdir/test1-sastt.base",
  #   ("$indir/sastt-case1.sys.rttm")
  # );
  # run_test(
  #   "test2-sastt",
  #   "$prefix -G -f rttm -F rttm -a -l english -h sastt",
  #   "$indir/example.glm",
  #   "$indir/sastt-case2.ref.rttm",
  #   "$expdir/test2-sastt.base",
  #   ("$indir/sastt-case2.sys.rttm")
  # );
  run_test(
    "test1-notag",
    "$prefix -l english -h hub5",
    "$indir/example.glm",
    "$indir/lvc_refe.notag.noat.stm",
    "$expdir/test1-notag.base",
    ("$indir/lvc_hyp.notag.ctm", "$indir/lvc_hyp2.notag.ctm")
  );
  run_test(
    "test1-notag-a",
    "$prefix -l english -h hub5 -a",
    "$indir/example.glm",
    "$indir/lvc_refe.notag.noat.stm",
    "$expdir/test1-notag-a.base",
    ("$indir/lvc_hyp.notag.ctm", "$indir/lvc_hyp2.notag.ctm")
  );
  run_test(
    "test1",
    "$prefix -l english -h hub5 -V",
    "$indir/example.glm",
    "$indir/lvc_refe.stm",
    "$expdir/test1.base",
    ("$indir/lvc_hyp.ctm", "$indir/lvc_hyp2.ctm")
  );
  run_test(
    "testArb",
    "$prefix -l arabic -h hub5 -V -H -T -d",
    "$indir/test.arb2004.glm",
    "$indir/test.arb2004.txt.stm",
    "$expdir/testArb.base",
    ("$indir/test.arb2004.txt.ctm")
  );
};
chdir($base);
die $@ if $@;
# runIt($operation, "test1", "-V", "../test_suite/example.glm", "hub5", "english",
#       "../test_suite/lvc_refe.stm",
#       "../test_suite/lvc_hyp.ctm ../test_suite/lvc_hyp2.ctm");
# runIt($operation, "testArb", "-V -H -T -d", "../test_suite/test.arb2004.glm", "hub5", "arabic",
#       "../test_suite/test.arb2004.txt.stm",
#       "../test_suite/test.arb2004.txt.ctm");