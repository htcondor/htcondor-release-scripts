#!/usr/bin/perl
use strict;
use warnings;
#
# (1) quit unless we have the correct number of command-line args
my $num_args = $#ARGV + 1;
my $base;
my $stable;
my $devel;
if ($num_args == 2) {
    $base = $ARGV[0];
    $stable = $ARGV[1];
} elsif ($num_args == 3) {
    $base = $ARGV[0];
    $stable = $ARGV[1];
    $devel = $ARGV[2];
} else {
    print "\nUsage: tickets.pl base stable [devel]\n";
    exit;
}

my $commit;
my $commits;
my $ticket;

my $git_log_command = "git log --no-decorate --name-only";
my %base_commits;
my %base_tickets;
my $base_commit;
my %stable_tickets;
my %devel_tickets;

print "Reading commits from base $base...\n";
$commits = 0;
open(my $BASE, "-|", "$git_log_command $base");
while(<$BASE>) {
    if (/^commit ([[:xdigit:]]+)/) {
        $commit = $1;
        $base_commits{$commit}++;
    }
    for my $ticket (/HTCONDOR-(\d+)/gi) { # Jira numbers
        $base_tickets{$ticket}++;
        $commits++;
    }
}
close($BASE);
print "Processed $commits commits with ticket numbers\n\n";

print "Reading commits from stable $stable...\n";
$commits = 0;
open(my $STABLE, "-|", "$git_log_command $stable");
while(<$STABLE>) {
    if (/^commit ([[:xdigit:]]+)/) {
        $commit = $1;
        $base_commit = $base_commits{$commit};
    }
    for my $ticket (/HTCONDOR-(\d+)/gi) { # Jira numbers
        if (!$base_commit) {
            $stable_tickets{$ticket}++;
            $commits++;
        }
    }
}
close($STABLE);
print "Processed $commits commits with ticket numbers\n\n";

if (!$devel) {
    print "Ticket summary:\n";
    for my $ticket (sort {$a<=>$b} keys(%stable_tickets)) {
        my $commits = $stable_tickets{$ticket};
        if ($base_tickets{$ticket}) {
            print "Old Ticket #$ticket with $commits commits";
        } else {
            print "New Ticket #$ticket with $commits commits";
        }
        print "     https://opensciencegrid.atlassian.net/browse/HTCONDOR-$ticket\n";
    }
} else {
    print "Reading commits from devel $devel...\n";
    $commits = 0;
    open(my $DEVEL, "-|", "$git_log_command $devel");
    while(<$DEVEL>) {
        if (/^commit ([[:xdigit:]]+)/) {
            $commit = $1;
            $base_commit = $base_commits{$commit};
        }
        for my $ticket (/HTCONDOR-(\d+)/gi) { # Jira numbers
            if (!($base_commit)) {
                $devel_tickets{$ticket}++;
                $commits++;
            }
        }
    }
    close($DEVEL);
    print "Processed $commits commits with ticket numbers\n\n";

    print "Ticket summary:\n";
    for my $ticket (sort {$a<=>$b} keys(%devel_tickets)) {
        my $commits = $devel_tickets{$ticket};
        if ($base_tickets{$ticket}) {
            if ($stable_tickets{$ticket}) {
                print "Old Stable Ticket #$ticket with $commits commits";
            } else {
                print "Old Devel  Ticket #$ticket with $commits commits";
            }
        } else {
            if ($stable_tickets{$ticket}) {
                print "New Stable Ticket #$ticket with $commits commits";
            } else {
                print "New Devel  Ticket #$ticket with $commits commits";
            }
        }
        print "     https://opensciencegrid.atlassian.net/browse/HTCONDOR-$ticket\n";
    }
}
