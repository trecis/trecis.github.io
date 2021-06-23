#!/usr/bin/perl -w

use strict;

use JSON;

# Check a TREC 2021A Incident Streams track
# submission for various common errors:
#      * multiple run tags
#      * unknown incidents
#      * unknown or missing tweet (approximate check)
#      * duplicate tweet for same incident 
#      * mismatch in category lengths
#      * errors in category score and label types
# Messages regarding submission are printed to an error log
#
# Results input file is a JSON-newline-delimited file of the form:
#       {
#           "topic": "TRECIS-CTIT-H-Test-022",
#           "runtag": "myrun",
#           "tweet_id": "991855886363541507",
#           "priority": 0.67,
#           "info_type_scores": [0.2,0.31,0.1,0.7,0.0,...],
#           "info_type_labels": [0,0,0,1,0,...]
#       }
#


# Change this variable for directory where error log should be put
my $errlog_dir = ".";

# If more than 25 errors, then stop processing; something drastically
# wrong with the file.
my $MAX_ERRORS = 25; 
my %collsize = (
                "TRECIS-CTIT-H-076", 32172,
                "TRECIS-CTIT-H-077", 529,
                "TRECIS-CTIT-H-078", 8246,
                "TRECIS-CTIT-H-079", 6339,
                "TRECIS-CTIT-H-080", 834,
                "TRECIS-CTIT-H-081", 9585,
                "TRECIS-CTIT-H-082", 13628,
                "TRECIS-CTIT-H-083", 26920,
                "TRECIS-CTIT-H-084", 8515,
                "TRECIS-CTIT-H-085", 49544,
                "TRECIS-CTIT-H-086", 26887,
                "TRECIS-CTIT-H-087", 4940,
                "TRECIS-CTIT-H-088", 49951,
                "TRECIS-CTIT-H-089", 18870,
                "TRECIS-CTIT-H-090", 49951,
                "TRECIS-CTIT-H-091", 49951,
                "TRECIS-CTIT-H-092", 49951,
                "TRECIS-CTIT-H-093", 49951,
                "TRECIS-CTIT-H-094", 6169,
                "TRECIS-CTIT-H-095", 49796,
                "TRECIS-CTIT-H-096", 2092,
                "TRECIS-CTIT-H-097", 49615,
                "TRECIS-CTIT-H-098", 49266,
                "TRECIS-CTIT-H-099", 48998,
                "TRECIS-CTIT-H-100", 49118,
                "TRECIS-CTIT-H-101", 49951,
                "TRECIS-CTIT-H-102", 49292,
                "TRECIS-CTIT-H-103", 5607,
                "TRECIS-CTIT-H-104", 49051,
                "TRECIS-CTIT-H-105", 48864,
                "TRECIS-CTIT-H-106", 49574,
                "TRECIS-CTIT-H-107", 49446,
                "TRECIS-CTIT-H-108", 26865,
                "TRECIS-CTIT-H-109", 16911,
                "TRECIS-CTIT-H-110", 43320,
                "TRECIS-CTIT-H-111", 49739,
                "TRECIS-CTIT-H-112", 16526,
                "TRECIS-CTIT-H-113", 48000,
                "TRECIS-CTIT-H-114", 48537,
                "TRECIS-CTIT-H-115", 7783,
                "TRECIS-CTIT-H-116", 49354,
                "TRECIS-CTIT-H-117", 6551,
                "TRECIS-CTIT-H-118", 42533,
                "TRECIS-CTIT-H-119", 41143,
                "TRECIS-CTIT-H-120", 48463,
                "TRECIS-CTIT-H-121", 48718,
                "TRECIS-CTIT-H-122", 22810,
			   );

my @incidents = sort keys %collsize;

my %tweets;				   # hash of tweets that have been categorized
my $results_file;		   # input file to be checked; it is an
                           #   input argument to the script
my $line;				   # current input line
my $line_num;              # current input line number
my $errlog;                # file name of error log
my $num_errors;            # flag for errors detected
my $incident;
my ($tweetid,$q0,$importance,$rank,$cat_scores_list,$cat_labels_list,$tag);
my ($clist,$cat,$cerror,$pos);
my %numcat;
my $validnumcats = 25;
my $q0warn = 0;
my $run_id;
my ($i);

my $usage = "Usage: $0 resultsfile\n";
$#ARGV == 0 || die $usage;

$results_file = $ARGV[0];

foreach $incident (@incidents) {
    $numcat{$incident} = 0;
}

open RESULTS, "gunzip -c $results_file |" ||
    die "Unable to open results file $results_file: $!\n";

my @path = split "/", $results_file;
my $base = pop @path;
$errlog = $errlog_dir . "/" . $base . ".errlog";
open ERRLOG, ">$errlog" ||
    die "Cannot open error log for writing\n";


$num_errors = 0;
$line_num = 0;
$run_id = "";
while ($line = <RESULTS>) {
    chomp $line;
    next if ($line =~ /^\s*$/);

    undef $tag;

    # my @fields = split " ", $line;
    my $fields  = decode_json $line;

    $line_num++;
    
    if (scalar(keys(%$fields)) == 6) {
		# ($incident,$q0,$tweetid,$rank,$importance,$catlist,$tag) = @fields;
        $incident = $fields->{topic};
        $tweetid = $fields->{tweet_id};
        $importance = $fields->{priority};
        $cat_scores_list = $fields->{info_type_scores};
        $cat_labels_list = $fields->{info_type_labels};
        $tag = $fields->{runtag};
    } else {
		&error(sprintf("Wrong number of fields %d (expecting 6)"), scalar(keys(%$fields)));
		exit 255;
    }

    # make sure runtag is ok
    if (! $run_id) {			# first line --- remember tag 
		$run_id = $tag;
		if ($run_id !~ /^[A-Za-z0-9_.-]{1,20}$/) {
			&error("Run tag `$run_id' is malformed");
			next;
		}
    } else {				   # otherwise just make sure one tag used
		if ($tag ne $run_id) {
			&error("Run tag inconsistent (`$tag' and `$run_id')");
			next;
		}
    }

    # make sure incident is known
	if ($incident =~ /^\d+$/) {
		$incident =~ s/0?(\d+)$/TRECIS-CTIT-H-Test-0$1/;
	}
    if (!exists($numcat{$incident})) {
		&error("Unknown incident '$incident'");
		$incident = 0;
		next;
    }  
    

    # make sure tweetid is plausible and not duplicated
    if ($tweetid =~ /^[0-9]{17,19}$/) {	# valid tweet to the extent we will check
		if (exists $tweets{$tweetid} && $tweets{$tweetid} eq $incident) {
			&error("Tweet `$tweetid' categorized more than once for incident $incident");
			next;
		}
		$tweets{$tweetid} = $incident;
    } else {					# invalid tweet id
		&error("Invalid tweetid `$tweetid'");
		next;
    }

    if ($importance < 0.0 || $importance > 1.0) {
		&error("Importance scores must be between 0 and 1");
		next;
    }

    if (scalar(@{$cat_scores_list}) != $validnumcats) {
        &error("Category scores must be an array of `$validnumcats' floating-point numbers.");
        next;
    }

    if (scalar(@{$cat_labels_list}) != $validnumcats) {
        &error("Category labels must be an array of `$validnumcats' integers, 0 or 1.");
        next;
    }

    my @cat_scores = @{$cat_scores_list};
    if (scalar @cat_scores != $validnumcats) {
        &error("Category scores should have `$validnumcats' categories, " . scalar @cat_scores . " found");
        next;
    }
    for my $catscore (@cat_scores) {
        if ($catscore < 0.0 || $catscore > 1.0) {
            &error("Category value `$catscore' must be between 0.0 and 1.0 inclusive");
        }
        next;
    }



    my @cat_labels = @{$cat_labels_list};
    if (scalar @cat_labels != $validnumcats) {
        &error("Category labels should have `$validnumcats' categories, " . scalar @cat_labels . " found");
        next;
    }
    for my $catlabel (@cat_labels) {
        if ($catlabel != 0 && $catlabel != 1) {
            &error("Category label `$catlabel' must be between 0 or 1.");
        }
        next;
    }

    $numcat{$incident}++;
}


# Do global checks:
#   warn if some incident doesn't have precisely the correct number
#   of tweets categorized
# foreach $incident (@incidents) { 
#    if ($numcat{$incident} != $collsize{$incident}) {
#            print ERRLOG ("run $results_file: Warning, only $numcat{$incident} tweets categorized for incident $incident; expected $collsize{$incident}.\n");
#    }
#}

print ERRLOG "Finished processing $results_file\n";
close ERRLOG || die "Close failed for error log $errlog: $!\n";

if ($num_errors) {
	exit 255;
}
exit 0;


# print error message, keeping track of total number of errors
sub error {
	my $msg_string = pop(@_);

    print ERRLOG 
		"run $results_file: Error on line $line_num --- $msg_string\n";

    $num_errors++;
    if ($num_errors > $MAX_ERRORS) {
        print ERRLOG "$0 of $results_file: Quit. Too many errors!\n";
        close ERRLOG ||
			die "Close failed for error log $errlog: $!\n";
		exit 255;
    }
}
