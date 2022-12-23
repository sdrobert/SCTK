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
  -s <path>: Path to SCLITE executable
  -d:        If set, sclite was compiled with GNU diff support
  -t:        If set, sclite was compiled with the SLM toolkit
  -f <str>:  Additional flags to pass to sclite
";

my $has_diff = "";
my $has_slm = "";
my $outdir;
my $indir = ".";
my $sclite = "sclite";
my $scl_flags = "";
my $perl = $Config{perlpath};

GetOptions(
  "o=s" => sub {
    my ($opt_name, $opt_value) = @_;
    die "Error -$opt_name expected directory name, got $opt_value"
      unless (-d $opt_value || mkdir($opt_value));
    $outdir = File::Spec->rel2abs(File::Spec->canonpath($opt_value));
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
    $sclite = File::Spec->rel2abs(File::Spec->canonpath($opt_value));
  },
  "d" => \$has_diff,
  "t" => \$has_slm,
  "f=s" => \$scl_flags
) or die "$usage";

unless (defined($outdir)) {
  $outdir = File::Temp->newdir();
}

# some tests require this
chdir($indir) or die "Could not move to directory $indir";

sub compare_files {
  # tsclite.sh applies the following options in its diff command:
  # -x CVS: exclude any base names matching "CVS" (this is actually done by a
  #         grep on the diff, but I'm assuming it's for the same purpose)
  # -I '[cC]reation[ _]date': exclude lines with a creation date
  my ($test_id, $relative_path, $exp_root, $act_root) = @_;
  # the -x stuff
  return 1 if ($relative_path =~ /^(|.*\/)(CVS)(\/.*|)$/);
  my $filtered_exp = File::Temp->new();
  my $filtered_act = File::Temp->new();
  open(my $unfiltered_exp, "<", "$exp_root/$relative_path")
    or die "$test_id failed: unable to open $exp_root/$relative_path";
  while (<$unfiltered_exp>) {
    # the -I stuff
    next if /[cC]reation[ _]date/;
    print $filtered_exp $_;
  }
  close($unfiltered_exp);
  close($filtered_exp);
  open(my $unfiltered_act, "<", "$act_root/$relative_path")
    or die "$test_id failed: unable to open $act_root/$relative_path";
  while (<$unfiltered_act>) {
    next if /[cC]reation[ _]date/;
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
    next if ($fn =~ /.*\.com$/);
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
    " -n $name -O $act_dir".
    " 1> ".File::Spec->catfile($act_dir, "$name.out").
    " 2> ".File::Spec->catfile($act_dir, "$name.err");
  
  # the 16_* series errors intentionally.
  system($cmd);

  foreach my $fn ("$act_dir/$name.sgml", "$act_dir/$name.nl.sgml") {
    next unless (-f $fn);
    my $tf = new File::Temp();
    open(my $fh, "<", $fn) or die("Could not open '$fn'");
    while (<$fh>) {
      s/creation_date="[^"]*"//;
      print $tf $_;
    }
    close($fh);
    close($tf);
    copy($tf->filename, $fn);
  }

  compare_directories($name, ".", "base", $act_dir) or die;
}

unless (-d "$outdir") {
  mkdir $outdir or die "Could not make directory";
}

my $prefix = "$sclite $scl_flags -f 0";

run_test(
  "test1",
  "Align Both Ref and Hyp transcripts. (one transcript to a line followed by an utterance id in parens)",
  "$prefix -r ./csrnab.ref -h ./csrnab.hyp -i wsj -o all snt spk dtl prf sgml nl.sgml"
);

run_test(
  "test1a",
  "Same as test1, but generating an sgml file, then piping to sclite for reports",
  "$prefix -P -o dtl prf < test1.sgml"
);

run_test(
  "test1b",
  "Same as test1, but using a language model for weights",
  "$prefix -r ./csrnab.ref -h ./csrnab.hyp -i wsj -L ./csrnab_r.blm -o sum wws prf",
  "SLM"
);

run_test(
  "test1c",
  "Same as test1, but using a language model for weights",
  "$prefix -r ./csrnab.ref -h ./csrnab.hyp -i wsj -w ./csrnab_r.wwl -o wws prf"
);

run_test(
  "test1d",
  "Same as test1, but producing a nl.sgml file",
  "$prefix -r ./csrnab.ref -h ./csrnab.hyp -i wsj -o nl.sgml"
);

run_test(
  "test1e",
  "Same as test1 but with utf-8 1 bytes per char",
  "$prefix -r ./csrnab.ref -h ./csrnab.hyp -i wsj -o all snt spk dtl prf sgml nl.sgml -e utf-8"
);

run_test(
  "test2",
  "Same as Test 1, but use Diff instead of DP alignments",
  "$prefix -r ./csrnab.ref -h ./csrnab.hyp -i wsj -o all -d",
  "DIFF"
);

run_test(
  "test3",
  "Align Segmental Time marks (STM) to Conversation time marks (CTM)",
  "$prefix -r ./lvc_ref.stm stm -h ./lvc_hyp.ctm ctm -o all lur prf"
);

run_test(
  "test3a",
  "Align Segmental Time marks (STM) to Conversation time marks (CTM) using the stm tag IGNORE_TIME_SEGMENT_IN_SCORING",
  "$prefix -r ./lvc_refe.stm stm -h ./lvc_hyp.ctm ctm -o all lur prf"
);

run_test(
  "test3b",
  "Align Segmental Time marks (STM) to Conversation time marks (CTM) with confidence scores",
  "$prefix -r ./lvc_ref.stm stm -h ./lvc_hypc.ctm ctm -o sum"
);

run_test(
  "test3c",
  "Test the output generated in lur when ther is no reference data",
  "$prefix -r ./lvc_refm.stm stm -h ./lvc_hypm.ctm ctm -o lur"
);

run_test(
  "test4",
  "Same as test 3, but using diff for alignment",
  "-$prefix r ./lvc_refe.stm stm -h ./lvc_hyp.ctm ctm -o all -d",
  "DIFF"
);

run_test(
  "test5",
  "Align STM to free formatted text (TXT)",
  "$prefix -r ./lvc_ref.stm stm -h ./lvc_hyp.txt txt -o all prf",
  "DIFF"
);

run_test(
  "test6",
  "Align Mandarin Chinese words using DIFF",
  "$prefix -e gb -r ./mand_ref.stm stm -h ./mand_hyp.ctm ctm -o all -d",
  "DIFF"
);

run_test(
  "test7",
  "Run some test cases through w/ D flag",
  "$prefix -r ./tests.ref -h ./tests.hyp -i spu_id -o all -F -D"
);

run_test(
  "test7_r",
  "Run some test cases through (reversing ref and hyp) w/ D flag",
  "$prefix -r ./tests.hyp -h ./tests.ref -i spu_id -o all -F -D",
);

run_test(
  "test7_noD",
  "Run some test cases through w/o D flag",
  "$prefix -r ./tests.ref -h ./tests.hyp -i spu_id -o all -F"
);

run_test(
  "test7_1",
  "Run some test cases through using inferred word boundaries, not changing ASCII words",
  "$prefix -r ./tests.ref -h ./tests.hyp -i spu_id -o all -S algo1 tests.lex"
);

run_test(
  "test7_2",
  "Run some test cases through using inferred word boundaries, changing ASCII words",
  "$prefix -r ./tests.ref -h ./tests.hyp -i spu_id -o all -S algo1 tests.lex ASCIITOO"
);

run_test(
  "test7_2a",
  "Run some test cases through using inferred word boundaries, changing ASCII words, using algo2",
  "$prefix -r ./tests.ref -h ./tests.hyp -i spu_id -o all -S algo2 tests.lex ASCIITOO"
);

run_test(
  "test7_3",
  "Run some test cases through using inferred word boundaries, not changing ASCII words and correct Fragments",
  "$prefix -r ./tests.ref -h ./tests.hyp -i spu_id -o all -S algo1 tests.lex -F"
);

run_test(
  "test7_4",
  "Run some test cases through using inferred word boundaries, changing ASCII words and correct Fragments",
  "$prefix -r ./tests.ref -h ./tests.hyp -i spu_id -o all -S algo1 tests.lex ASCIITOO -F"
);

run_test(
  "test7_5",
  "Run some test cases through, character aligning them and removing hyphens",
  "$prefix -r ./tests.ref -h ./tests.hyp -i spu_id -o all -c DH"
);

run_test(
  "test7_6",
  "Run some test cases through with utf-8 encoding",
  "$prefix -r ./tests.ref -h ./tests.hyp -i spu_id -o all sgml nl.sgml -F -D -e utf-8"
);

for my $utf("utf8-2bytes", "utf8-3bytes", "utf8-4bytes") {
  run_test(
    "test7-$utf",
    "Same as test 1 but with $utf",
    "$prefix -r ./tests.ref.$utf -h ./tests.hyp.$utf -i spu_id -o all sgml -F -D -e utf-8"
  );
}

run_test(
  "test8",
  "Align transcripts as character alignments",
  "$prefix -r ./csrnab1.ref -h ./csrnab1.hyp -i wsj -o all -c"
);

run_test(
  "test9",
  "Run the Mandarin, doing a character alignment",
  "$prefix -e gb -r ./mand_ref.stm stm -h ./mand_hyp.ctm ctm -o all dtl prf -c"
);

run_test(
  "test9_1",
  "Run the Mandarin, doing a character alignment, removing hyphens",
  "$prefix -e gb -r ./mand_ref.stm stm -h ./mand_hyp.ctm ctm -o all -c DH"
);

run_test(
  "test10",
  "Run the Mandarin, doing a character alignment, not affecting ASCII words",
  "$prefix -e gb -r ./mand_ref.stm stm -h ./mand_hyp.ctm ctm -o all prf -c NOASCII"
);

run_test(
  "test10_1",
  "Run the Mandarin, doing a character alignment, not affecting ASCII words, removing hyphens",
  "$prefix -e gb -r ./mand_ref.stm stm -h ./mand_hyp.ctm ctm -o all -c NOASCII DH"
);

run_test(
  "test11",
  "Run the Mandarin, doing the inferred word segmentation alignments, algo1",
  "$prefix -e gb -r ./mand_ref.stm stm -h ./mand_hyp.ctm ctm -o all -S algo1 mand.lex"
);

run_test(
  "test12",
  "Run the Mandarin, doing the inferred word segmentation alignments, algo1, scoring fragments as correct",
  "$prefix -e gb -r ./mand_ref.stm stm -h ./mand_hyp.ctm ctm -o all -S algo1 mand.lex -F"
);

run_test(
  "test13",
  "Run alignments on two CTM files, using DP Word alignments w/o D flag",
  "$prefix -r ./tima_ref.ctm ctm -h ./tima_hyp.ctm ctm -o all prf"
);

run_test(
  "test13_D",
  "Run alignments on two CTM files, using DP Word alignments w/ D flag",
  "$prefix -r ./tima_ref.ctm ctm -h ./tima_hyp.ctm ctm -o all prf -D"
);

run_test(
  "test13_a",
  "Run alignments on two CTM files, using Time-Mediated DP alignments w/o D flag",
  "$prefix -r ./tima_ref.ctm ctm -h ./tima_hyp.ctm ctm -o all -T"
);

run_test(
  "test13_aD",
  "Run alignments on two CTM files, using Time-Mediated DP alignments w/ D flag",
  "$prefix -r ./tima_ref.ctm ctm -h ./tima_hyp.ctm ctm -o all -T -D"
);

run_test(
  "test14_a",
  "Reduce the ref and hyp input files into the intersection of the inputs",
  "$prefix -r ./lvc_refr.stm stm -h ./lvc_hypr.ctm ctm -o all lur -m ref hyp"
);

run_test(
  "test14_b",
  "Reduce the ref and hyp input files to the intersection of the inputs using a reduced size hyp file",
  "$prefix -r ./lvc_ref.stm stm -h ./lvc_hypr.ctm ctm -o all lur -m ref hyp"
);

run_test(
  "test14_c",
  "Reduce the ref and hyp input files to the intersection of the inputs using a reduced size ref file",
  "$prefix -r ./lvc_refr.stm stm -h ./lvc_hyp.ctm ctm -o all lur -m ref hyp"
);

run_test(
  "test14_d",
  "Reduce the ref and hyp input files to the intersection of the inputs using a reduced size ref and hyp file",
  "$prefix -r ./lvc_refr.stm stm -h ./lvc_hypr.ctm ctm -o all lur -m hyp"
);

run_test(
  "test14_e",
  "Reduce the ref and hyp input files to the intersection of the inputs using a reduced size ref and hyp file (again?)",
  "$prefix -r ./lvc_refr.stm stm -h ./lvc_hypr.ctm ctm -o all lur -m ref"
);

run_test(
  "test15_a",
  "UTF-8 test - Cantonese no options",
  "$prefix -r ./test.cantonese.stm stm -h ./test.cantonese.ctm ctm -o all prf -e utf-8"
);

run_test(
  "test15_b",
  "UTF-8 test - Cantonese no options - Character scoring",
  "$prefix -r ./test.cantonese.stm stm -h ./test.cantonese.ctm ctm -o all prf -e utf-8 -c NOASCII DH"
);

run_test(
  "test15_c",
  "UTF-8 test - UTF-8 Turckish",
  "$prefix -r ./test.turkish.ref trn -h ./test.turkish.hyp -o all prf -e utf-8 babel_turkish -i spu_id"
);

run_test(
  "test15_d",
  "UTF-8 test - UTF-8 Ukranian",
  "$prefix -r ./test.ukranian.ref trn -h ./test.ukranian.hyp -o all prf -e utf-8 ukrainian -i spu_id"
);

my $n = 1;
for my $hyp ( "stm2ctm_missing.hyp-extra.ctm",
              "stm2ctm_missing.hyp-missall.ctm",
              "stm2ctm_missing.hyp-missfile1.ctm",
              "stm2ctm_missing.hyp-missfile1chanA.ctm",
              "stm2ctm_missing.hyp-missfile1chanb.ctm",
              "stm2ctm_missing.hyp-missfile2.ctm",
              "stm2ctm_missing.hyp-missfile2chanA.ctm",
              "stm2ctm_missing.hyp-missfile2chanB.ctm",
              "stm2ctm_missing.hyp.ctm") {
  run_test(
    "test16_".($n++),
    "Allow incomplete hyp CTM files - $hyp",
    "$prefix -r ./stm2ctm_missing.ref.stm stm -h ./$hyp ctm -o all prf"
  );
}

run_test(
  "test17",
  "Vietnamese case conversion",
  "$prefix -r ./test.vietnamese.ref.trn trn -h test.vietnamese.hyp.trn trn -i spu_id -o all prf -e utf-8 babel_vietnamese"
);