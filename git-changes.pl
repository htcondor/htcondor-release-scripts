#!/usr/bin/perl
use strict;
use warnings;
#
# (1) quit unless we have the correct number of command-line args
my $num_args = $#ARGV + 1;
my $start_date;
my $end_date;
if ($num_args == 2) {
    $start_date = $ARGV[0];
    $end_date = $ARGV[1];
} else {
    print "\nUsage: git-changes.pl start_date end_date\n";
    exit;
}

my $author;
my %authors;
my %lines_added;
my %lines_changed;
my %lines_deleted;
my $lines_added;
my $lines_deleted;
my $lines_changed;
my $delta;

my $git_log_command = "git log --no-merges --numstat --since $start_date --until $end_date";

#print "Reading commits...\n";
my $commits = 0;
open(my $LOG, "-|", "$git_log_command");
while(<$LOG>) {
    if (/^Author:\s*(.*)/) {
        $commits++;
        $author = $1;
        $author =~ s/^=//;
        # Remove email address
        $author =~ s/<.*>//;
        # Remove spaces
        $author =~ s/\s+//g;
        # Insert space before each capital letter
        $author =~ s/([A-Z(])/ $1/g;
        # Remove leading space
        $author =~ s/^ //;
        $author =~ s/- /-/;
        # Special Case for TJ
        $author =~ s/ *T J/TJ/;
        # Special case for McK
        $author =~ s/Mc /Mc/;
        # Special case for MacK
        $author =~ s/Mac /Mac/;
        # Consolidate users
        $author =~ s/^adesmet$/Alan De Smet/;
        $author =~ s/^adiel$/Adiel Yoaz/;
        $author =~ s/^akarp$/Anatoly Karp/;
        $author =~ s/^alderman$/Ian Alderman/;
        $author =~ s/^ballard$/Jeff Ballard/;
        $author =~ s/^benoit.roland$/Benoit Roland/;
        $author =~ s/^bgietzel$/Becky Gietzel/;
        $author =~ s/^Brian$/Brian Bockelman/;
        $author =~ s/^Brian Bockleman$/Brian Bockelman/;
        $author =~ s/^Brian P Bockelman$/Brian Bockelman/;
        $author =~ s/^bsong$/Bin Song/;
        $author =~ s/^bt$/Bill Taylor/;
        $author =~ s/^burnett$/Ben Burnett/;
        $author =~ s/^ckireyev$/Carey Kireyev/;
        $author =~ s/^coatsworth$/Mark Coatsworth/;
        $author =~ s/^danb$/Dan Bradley/;
        $author =~ s/^dhaval$/Dhaval Shah/;
        $author =~ s/^Dr Dave D$/Dave Dykstra/;
        $author =~ s/^duncan.macleod$/Duncan Macleod/;
        $author =~ s/^edquist$/Carl Edquist/;
        $author =~ s/^epaulson$/Erik Paulson/;
        $author =~ s/^faisal$/Faisal Kahn/;
        $author =~ s/^gquinn$/Greg Quinn/;
        $author =~ s/^Gregory Quinn$/Greg Quinn/;
        $author =~ s/^griswold$/Nate Griswold/;
        $author =~ s/^gthain$/Greg Thain/;
        $author =~ s/^Ian D. Alderman$/Ian Alderman/;
        $author =~ s/^ilikhan$/Ozcan Ilikhan/;
        $author =~ s/^James A. Kupsch$/Jim Kupsch/;
        $author =~ s/^Jamie Frey$/Jaime Frey/;
        $author =~ s/^jasoncpatton$/Jason Patton/;
        $author =~ s/^jmeehean$/Joe Meehean/;
        $author =~ s/^John Knoeller$/John (TJ) Knoeller/;
        $author =~ s/^johnbent$/John Bent/;
        $author =~ s/^jfrey$/Jaime Frey/;
        $author =~ s/^jbasney$/Jim Basney/;
        $author =~ s/^kupsch$/Jim Kupsch/;
        $author =~ s/^matt$/Matthew Farrellee/;
        $author =~ s/^matyas$/Matyas Selmeci/;
        $author =~ s/^ncoleman$/Nick Coleman/;
        $author =~ s/^next M J/nextMJ/;
        $author =~ s/^nleroy$/Nick Le Roy/;
        $author =~ s/^nmueller$/Nate Mueller/;
        $author =~ s/^Ozcan I L I K H A N$/Ozcan Ilikhan/;
        $author =~ s/^parag$/Parag Mhashilkar/;
        $author =~ s/^pavlo$/Andy Pavlo/;
        $author =~ s/^Pete Keller$/Peter Keller/;
        $author =~ s/^pfc$/Peter Couvares/;
        $author =~ s/^pruyne$/Jim Pruyne/;
        $author =~ s/^psilord$/Peter Keller/;
        $author =~ s/^R Hofsaess/RHofsaess/;
        $author =~ s/^raman$/Rajesh Raman/;
        $author =~ s/^rcmallen$/Raghu Mallena/;
        $author =~ s/^Rob Rati$/Robert Rati/;
        $author =~ s/^Robert$/Robert Rati/;
        $author =~ s/^roy$/Alain Roy/;
        $author =~ s/^sashwin$/Shrinivas Ashwin/;
        $author =~ s/^Scott Kronenfeld$/Scot Kronenfeld/;
        $author =~ s/^shuyang$/Shuyang (Shannon) Wang/;
        $author =~ s/^shuyangwang$/Shuyang (Shannon) Wang/;
        $author =~ s/^slebodnik$/Lukas Slebodnik/;
        $author =~ s/^smoler$/Karen Miller/;
        $author =~ s/^smurphy$/Sean Murphy/;
        $author =~ s/^solomon$/Marvin Solomon/;
        $author =~ s/^stanis$/Tom Stanis/;
        $author =~ s/^stolley$/Colin Stolley/;
        $author =~ s/^tmckay$/Trevor McKay/;
        $author =~ s/^tannenba$/Todd Tannenbaum/;
        $author =~ s/^thain$/Greg Thain/;
        $author =~ s/^tim$/Tim Theisen/;
        $author =~ s/^Timothy Clair$/Timothy St. Clair/;
        $author =~ s/^thakur$/Dhrubajyoti Borthakur/;
        $author =~ s/^TJ Knoeller$/John (TJ) Knoeller/;
        $author =~ s/^Todd L. Miller$/Todd L Miller/;
        $author =~ s/^Todd Miller$/Todd L Miller/;
        $author =~ s/^Todd Sleepyhead Tannenbaum$/Todd Tannenbaum/;
        $author =~ s/^tristan$/Tristan Halvorson/;
        $author =~ s/^weber$/Jeff Weber/;
        $author =~ s/^wenger$/Kent Wenger/;
        $author =~ s/^wright$/Derek Wright/;
        $author =~ s/^yoderme$/Mike Yoder/;
        $author =~ s/^zmiller$/Zach Miller/;
        $author =~ s/^zs$/Su Zhang/;
        $authors{$author}++;
    } elsif (/^(\d+)\s+(\d+)\s+/) {
        my $lines_added = $1;
        my $lines_deleted = $2;
        my $lines_changed;
        #print("Add: $lines_added, Delete: $lines_deleted\n");
        if ($lines_added > $lines_deleted) {
            $lines_changed = $lines_deleted;
            $lines_deleted = 0;
            $lines_added = $lines_added - $lines_changed;
        } else {
            $lines_changed = $lines_added;
            $lines_added = 0;
            $lines_deleted = $lines_deleted - $lines_changed;
        }
        #print("Add: $lines_added, Changed: $lines_changed, Delete: $lines_deleted\n");
        $lines_added{$author} += $lines_added;
        $lines_changed{$author} += $lines_changed;
        $lines_deleted{$author} += $lines_deleted;
    }
}
close($LOG);
#print "Processed $commits\n\n";

format Changes =
@###### @###### @###### @###### @###### @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$commits, $lines_added, $lines_changed, $lines_deleted, $delta, $author
.
$~ = 'Changes';

print "Commits   Added Changed Deleted   Delta Author\n";
print "------- ------- ------- ------- ------- ------\n";

my $total_authors;
my $total_commits;
my $total_lines_added;
my $total_lines_changed;
my $total_lines_deleted;

for $author (sort {uc($a) cmp uc($b)} keys(%authors)) {
    $commits = $authors{$author};
    $lines_added = $lines_added{$author};
    $lines_changed = $lines_changed{$author};
    $lines_deleted = $lines_deleted{$author};
    $delta = $lines_added - $lines_deleted;
    $total_authors++;
    $total_commits += $commits;
    $total_lines_added += $lines_added;
    $total_lines_changed += $lines_changed;
    $total_lines_deleted += $lines_deleted;
    write;
}
$author = "Grand total from $total_authors authors";
$commits = $total_commits;
$lines_added = $total_lines_added;
$lines_changed = $total_lines_changed;
$lines_deleted = $total_lines_deleted;
$delta = $lines_added - $lines_deleted;
write;
