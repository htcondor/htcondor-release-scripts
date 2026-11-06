#!/usr/bin/env perl

use strict;
use warnings;
use File::Find;
use File::Temp qw(tempfile);
use Getopt::Long qw(GetOptions);
use RPM2;

my $retain   = 1;
my $dry_run  = 0;
my $verbose  = 0;
my @names;
my $gpg_key;
my $gpg_home;

GetOptions(
    'retain=i'   => \$retain,
    'dry-run'    => \$dry_run,
    'verbose'    => \$verbose,
    'name=s@'    => \@names,
    'gpg-key=s'  => \$gpg_key,
    'gpg-home=s' => \$gpg_home,
) or die usage();

my $root = shift @ARGV or die usage();

die "--retain must be >= 1\n" unless $retain >= 1;
die "--gpg-key is required\n" unless defined $gpg_key && $gpg_key ne '';

@names = map { split /,/, $_ } @names;
@names = @names ? @names : qw(snapshot alpha beta release);

verify_command_available('createrepo');
verify_command_available('gpg');
verify_command_available('rpmdev-vercmp');

if (defined $gpg_home && !-d $gpg_home) {
    die "--gpg-home does not exist or is not a directory: $gpg_home\n";
}

verify_gpg_key_exists($gpg_key, $gpg_home);
verify_gpg_signing_works($gpg_key, $gpg_home);

my %wanted = map { $_ => 1 } @names;
my %target_dir_seen;
my @target_dirs;

find(
    {
        wanted => sub {
            return unless -d $_;
            my $base = $_;
            if ($wanted{$base}) {
                my $dir = $File::Find::name;
                return if $target_dir_seen{$dir}++;
                push @target_dirs, $dir;
            }
        },
        no_chdir => 1,
    },
    $root
);

if (!@target_dirs) {
    print "No matching directories found under $root\n";
    exit 0;
}

vprint("Matched repository directories:\n");
for my $dir (sort @target_dirs) {
    vprint("  $dir\n");
}

my %groups;

for my $dir (@target_dirs) {
    find(
        {
            wanted => sub {
                return unless -f $_;
                return unless $_ =~ /\.rpm$/i;

                my $path = $File::Find::name;
                vprint("Inspecting RPM: $path\n");

                my $rpm;
                eval { $rpm = RPM2->open_rpm($path); };
                if ($@ || !$rpm) {
                    warn "Skipping unreadable RPM metadata: $path\n";
                    return;
                }

                my $name    = eval { $rpm->tag('NAME') };
                my $epoch   = eval { $rpm->tag('EPOCH') };
                my $version = eval { $rpm->tag('VERSION') };
                my $release = eval { $rpm->tag('RELEASE') };
                my $arch    = eval { $rpm->tag('ARCH') } || 'noarch';

                unless (defined $name && defined $version && defined $release) {
                    warn "Skipping RPM missing NAME, VERSION, or RELEASE: $path\n";
                    return;
                }

                my $key = join('|', $dir, $name, $arch);
                push @{ $groups{$key} }, {
                    path    => $path,
                    dir     => $dir,
                    name    => $name,
                    epoch   => (defined $epoch && $epoch ne '' ? $epoch : 0),
                    version => $version,
                    release => $release,
                    arch    => $arch,
                };
            },
            no_chdir => 1,
        },
        $dir
    );
}

my @to_remove;
my @to_keep;
my %would_sign_dirs;

for my $key (sort keys %groups) {
    my @rpms = @{ $groups{$key} };

    @rpms = sort {
        rpm_native_vercmp(
            rpm_full_evr($b),
            rpm_full_evr($a),
        )
    } @rpms;

    vprint("Group $key has " . scalar(@rpms) . " RPM(s)\n");

    for my $i (0 .. $#rpms) {
        if ($i < $retain) {
            push @to_keep, $rpms[$i];
        } else {
            push @to_remove, $rpms[$i];
            $would_sign_dirs{ $rpms[$i]{dir} } = 1;
        }
    }
}

print "Retention count: $retain\n";
print "Mode: " . ($dry_run ? "dry-run" : "delete") . "\n\n";

print "Retained files:\n";
for my $item (sort { $a->{path} cmp $b->{path} } @to_keep) {
    print "  KEEP   $item->{path}  [" . display_nvr($item) . ".$item->{arch}]\n";
}

print "\nFiles to remove:\n";
for my $item (sort { $a->{path} cmp $b->{path} } @to_remove) {
    print "  REMOVE $item->{path}  [" . display_nvr($item) . ".$item->{arch}]\n";
}

if ($dry_run) {
    print "\nRepository directories that would be rebuilt and signed:\n";
    if (%would_sign_dirs) {
        for my $dir (sort keys %would_sign_dirs) {
            print "  SIGN   $dir\n";
        }
    } else {
        print "  (none)\n";
    }

    print "\nDry run complete. No files were removed.\n";
    exit 0;
}

my %changed_dirs;
my @delete_failures;

for my $item (@to_remove) {
    if (unlink $item->{path}) {
        print "Deleted $item->{path}\n";
        $changed_dirs{ $item->{dir} } = 1;
    } else {
        my $msg = "Failed to delete $item->{path}: $!";
        warn "$msg\n";
        push @delete_failures, $msg;
    }
}

if (!%changed_dirs) {
    print "No files were removed; repository metadata not updated.\n";
    if (@delete_failures) {
        die "One or more RPM deletions failed.\n";
    }
    exit 0;
}

for my $dir (sort keys %changed_dirs) {
    run_createrepo($dir);
    run_gpg_sign($dir, $gpg_key, $gpg_home);
}

if (@delete_failures) {
    die "One or more RPM deletions failed.\n";
}

exit 0;

sub vprint {
    return unless $verbose;
    print @_;
}

sub verify_command_available {
    my ($cmd) = @_;

    for my $path (split /:/, ($ENV{PATH} // '')) {
        my $full = "$path/$cmd";
        return if -f $full && -x $full;
    }

    die "Required command not found in PATH: $cmd\n";
}

sub verify_gpg_key_exists {
    my ($key, $home) = @_;

    my @cmd = ('gpg', '--list-secret-keys', '--with-colons', $key);
    push @cmd, ('--homedir', $home) if defined $home;

    print "Verifying GPG secret key exists\n";
    print "+ " . shell_quote(@cmd) . "\n";

    run_command(\@cmd, "gpg secret key check failed");
}

sub verify_gpg_signing_works {
    my ($key, $home) = @_;

    my ($fh, $tmpfile) = tempfile('cleanup_old_rpms_gpg_test_XXXXXX', DIR => '/tmp', UNLINK => 1);
    print {$fh} "gpg test\n" or die "Failed to write temporary file $tmpfile: $!\n";
    close $fh or die "Failed to close temporary file $tmpfile: $!\n";

    my $sigfile = "$tmpfile.asc";

    my @cmd = (
        'gpg',
        '--yes',
        '--armor',
        '--detach-sign',
        '--local-user', $key,
        '--output', $sigfile,
    );

    push @cmd, ('--homedir', $home) if defined $home;
    push @cmd, $tmpfile;

    print "Verifying GPG signing works before processing repositories\n";
    print "+ " . shell_quote(@cmd) . "\n";

    eval {
        run_command(\@cmd, "gpg test signing failed");
        1;
    } or do {
        my $err = $@ || "unknown error\n";
        unlink $tmpfile if -e $tmpfile;
        unlink $sigfile if -e $sigfile;
        die $err;
    };

    unlink $sigfile if -e $sigfile;
    unlink $tmpfile if -e $tmpfile;
}

sub run_createrepo {
    my ($dir) = @_;

    my @cmd = ('createrepo', '--update', $dir);
    print "+ " . shell_quote(@cmd) . "\n";

    run_command(\@cmd, "createrepo failed for $dir");
}

sub run_gpg_sign {
    my ($dir, $key, $home) = @_;

    my $repomd = "$dir/repodata/repomd.xml";
    die "Missing metadata file after createrepo: $repomd\n" unless -f $repomd;

    my @cmd = (
        'gpg',
        '--yes',
        '--armor',
        '--detach-sign',
        '--local-user', $key,
        '--output', "$repomd.asc",
    );

    push @cmd, ('--homedir', $home) if defined $home;
    push @cmd, $repomd;

    print "+ " . shell_quote(@cmd) . "\n";

    run_command(\@cmd, "gpg signing failed for $dir");
}

sub run_command {
    my ($cmd_ref, $label) = @_;

    my $rc = system(@{$cmd_ref});

    if ($rc == -1) {
        die "$label: failed to execute: $!\n";
    }

    if ($rc & 127) {
        die sprintf("%s: terminated by signal %d\n", $label, ($rc & 127));
    }

    my $exit = $rc >> 8;
    if ($exit != 0) {
        die "$label: exit code $exit\n";
    }

    return 1;
}

sub rpm_full_evr {
    my ($item) = @_;
    my $epoch = defined $item->{epoch} && $item->{epoch} ne '' ? $item->{epoch} : 0;
    my $ver   = $item->{version};
    my $rel   = $item->{release};
    return "${epoch}:${ver}-${rel}";
}

sub rpm_native_vercmp {
    my ($left, $right) = @_;

    return 0 if $left eq $right;

    my @cmd = ('rpmdev-vercmp', $left, $right);
    vprint("+ " . shell_quote(@cmd) . "\n");

    my $output = qx{rpmdev-vercmp @{[ shell_quote($left) ]} @{[ shell_quote($right) ]} 2>&1};
    my $status = $?;

    if ($status == -1) {
        die "rpmdev-vercmp failed to execute: $!\n";
    }

    if ($status & 127) {
        die sprintf("rpmdev-vercmp terminated by signal %d\n", ($status & 127));
    }

    my $exit = $status >> 8;
    die "rpmdev-vercmp failed for '$left' vs '$right': $output"
        if $exit != 0 && $exit != 11;

    return -1 if $output =~ /is older than/;
    return  1 if $output =~ /is newer than/;
    return  0 if $output =~ /are identical/;

    die "Unable to parse rpmdev-vercmp output for '$left' vs '$right': $output";
}

sub display_nvr {
    my ($item) = @_;
    my $prefix = ($item->{epoch} && $item->{epoch} ne '0') ? "$item->{epoch}:" : '';
    return "$item->{name}-$prefix$item->{version}-$item->{release}";
}

sub shell_quote {
    return join ' ', map {
        my $s = $_;
        if ($s eq '') {
            "''";
        } elsif ($s =~ /[^A-Za-z0-9_\-\.\:\/]/) {
            $s =~ s/'/'"'"'/g;
            "'$s'";
        } else {
            $s;
        }
    } @_;
}

sub usage {
    return <<'USAGE';
Usage:
  $0 [options] <root-path>

Options:
  --retain N          Number of most recent versions to keep (default: 1)
  --dry-run           Show what would be removed, retained, rebuilt, and signed
  --verbose           Print additional progress information
  --name NAME         Directory name to process; may be repeated or comma-separated
                      Defaults to: snapshot, alpha, beta, release
  --gpg-key KEYID     GPG key ID, fingerprint, or uid to sign with (required)
  --gpg-home PATH     GPG home directory to use

Examples:
  $0 --dry-run --gpg-key ABCDEF1234567890 /srv/repos
  $0 --retain 3 --gpg-key ABCDEF1234567890 /srv/repos
  $0 --verbose --gpg-home /root/.gnupg --gpg-key repo-signing@example.com --name release /srv/repos

Notes:
  This script requires: createrepo, gpg, rpmdev-vercmp, and the Perl RPM2 module.
USAGE
}
