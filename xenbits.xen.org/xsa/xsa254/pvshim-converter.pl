#!/usr/bin/perl -w
#
# usage:
#   pvshim-converter [OPTIONS] OLD-CONFIG NEW-CONFIG
#
# options:
#   --qemu PATH-TO-QEMU        filename of qemu-system-i386
#   --sidecars-directory DIR   default is /var/lib/xen/pvshim-sidecars
#   --shim SHIM                overrides domain config file
#   --debug                    verbose, and leaves sidecar prep dir around
#
# What we do
#
#  read existing config file using python
#  determine kernel, ramdisk and cmdline
#  use them to produce sidecar and save it under domain name
#  mess with the things that need to be messed with
#  spit out new config file

use strict;

use Getopt::Long;
use JSON;
use IO::Handle;
use POSIX;
use Fcntl qw(:flock);

our $debug;

sub runcmd {
    print STDERR "+ @_\n" if $debug;
    $!=0; $?=0; system @_ and die "$_[0]: $! $?";
}

our $qemu;
our $shim;
our $sidecars_dir = '/var/lib/xen/pvshim-sidecars';

GetOptions('qemu=s' => \$qemu,
           'sidecars-directory=s' => \$sidecars_dir,
           'shim=s' => \$shim,
           'debug' => \$debug)
    or die "pvshim-converter: bad options\n";

@ARGV==2 or die "pvshim-converter: need old and new config filenames";

our ($in,$out) = @ARGV;

our $indata;

if ($in ne '-') {
    open I, '<', "$in" or die "open input config file: $!\n";
} else {
    open I, '<&STDIN' or die $!;
}
{
    local $/;
    $indata = <I>;
}
I->error and die $!;
close I;

open P, "-|", qw(python2 -c), <<END, $indata or die $!;
import sys
import json
l = {}
exec sys.argv[1] in l
for k in l.keys():
	if k.startswith("_"):
		del l[k]
print json.dumps(l)
END

our $c;

{
    local $/;
    $_ = <P>;
    $!=0; $?=0; close P or die "$! $?";
    $c = decode_json $_;
}

die "no domain name ?" unless exists $c->{name};
die "bootloader not yet supported" if $c->{bootloader};
die "no kernel" unless $c->{kernel};

our $sidecar = $c->{pvshim_sidecar_path} || "$sidecars_dir/$c->{name}.iso";
our $dmwrap = $c->{pvshim_sidecar_path} || "$sidecars_dir/$c->{name}.dm";

$shim ||= $c->{pvshim_path};
$shim ||= '/usr/local/lib/xen/boot/xen-shim';

our $shim_cmdline = $c->{pvshim_cmdline} || 'console=com1 com1=115200n1';
$shim_cmdline .= ' '.$c->{pvshim_extra} if $c->{pvshim_extra};

our $kernel_cmdline = $c->{cmdline} || '';
$kernel_cmdline .= ' root='.$c->{root} if $c->{root};
$kernel_cmdline .= ' '.$c->{extra} if $c->{extra};

print "pvshim-converter: creating sidecar in $sidecar\n";

runcmd qw(mkdir -m700 -p --), $sidecars_dir;

open L, ">", "$sidecar.lock" or die "$sidecar.lock: open $!";
flock L, LOCK_EX or die "$sidecar.lock: lock: $!";

my $sd = "$sidecar.dir";

system qw(rm -rf --), $sd;
mkdir $sd, 0700;

runcmd qw(cp --), $shim, "$sd/shim";
runcmd qw(cp --), $c->{kernel}, "$sd/kernel";
runcmd qw(cp --), $c->{ramdisk}, "$sd/ramdisk" if $c->{ramdisk};

my $grubcfg = <<END;
serial --unit=0 --speed=9600 --word=8 --parity=no --stop=1
terminal_input serial
terminal_output serial

set timeout=0

menuentry 'Xen shim' {
	insmod gzio
	insmod xzio
        multiboot (cd)/shim placeholder $shim_cmdline
        module (cd)/kernel placeholder $kernel_cmdline
        module (cd)/ramdisk
}
END

runcmd qw(mkdir -p --), "$sd/boot/grub";
open G, ">", "$sd/boot/grub/grub.cfg" or die "$sd, grub.cfg: $!";
print G $grubcfg or die $!;
close G or die $!;

unlink "$sidecar.new" or $!==ENOENT or die "$sidecar.new: rm: $!";
runcmd qw(grub-mkrescue -o), "$sidecar.new", "$sidecar.dir";
if (!stat "$sidecar.new") {
    $!==ENOENT or die "$sidecar.new: stat: $!";

    print STDERR <<END;
pvshim-converter: grub-mkrescue exited with status zero but failed to make iso.
NB that grub-mkrescue has a tendency to lie in its error messages.
END
    my $missing;
    foreach my $check (qw(xorriso mformat)) {
        $missing |= system qw(sh -c), "type $check";
    }

    if ($missing) {
        print STDERR <<END;
You seem to have some program(s) missing which grub-mkrescue depends on,
see above.  ("mformat" is normally in the package "mtools".)
Installing those programs will probably help.
END
    } else {
        print STDERR <<END;
And older grub-mkrescue has a tendency not to notice certain problems.
Maybe strace will tell you what is wrong.  :-/
END
    }
    die "pvshim-converter: grub-mkrescue did not make iso\n";
}

runcmd qw(rm -rf --), "$sidecar.dir" unless $debug;

open Q, ">", "$dmwrap.new" or die "$dmwrap: $!";
print Q <<'END_DMWRAP' or die $!;
#!/bin/bash

set -x
: "$@"
set +x

newargs=()

newarg () {
    newargs+=("$1")
}

while [ $# -gt 1 ]; do
    case "$1" in
	-no-shutdown|-nodefaults|-no-user-config)
	    newarg "$1"; shift
	    ;;
	-xen-domid|-chardev|-mon|-display|-boot|-m|-machine)
	    newarg "$1"; shift
	    newarg "$1"; shift
	    ;;
        -name)
            newarg "$1"; shift
            name="$1"; shift
            newarg "$name"
            ;;
	-netdev|-cdrom)
	    : fixme
	    newarg "$1"; shift
	    newarg "$1"; shift
	    ;;
	-drive|-kernel|-initrd|-append|-vnc)
	    shift; shift
	    ;;
	-device)
	    shift
	    case "$1" in
		XXXrtl8139*)
		    newarg "-device"
		    newarg "$1"; shift
		    ;;
		*)
		    shift
		    ;;
	    esac
	    ;;
	*)
	    echo >&2 "warning: unexpected argument $1 being passed through"
	    newarg "$1"; shift
	    ;;
    esac
done

#if [ "x$name" != x ]; then
#    logdir=/var/log/xen
#    logfile="$logdir/shim-$name.log"
#    savelog "$logfile" ||:
#    newarg -serial
#    newarg "file:$logfile"
#fi
END_DMWRAP

if ($qemu) {
    printf Q <<'END_DMWRAP', $qemu or die $!;
    exec '%s' "${newargs[@]}"
END_DMWRAP
} else {
    print Q <<'END_DMWRAP' or die $!;
set -x
for path in /usr/local/lib/xen/bin /usr/lib/xen/bin /usr/local/bin /usr/bin; do
    if test -e $path/qemu-system-i386; then
        exec $path/qemu-system-i386 "${newargs[@]}"
    fi
done
echo >&2 'could not exec qemu'
exit 127
END_DMWRAP
}

chmod 0755, "$dmwrap.new" or die "$dmwrap: chmod: $!";

close Q or die $!;

rename "$sidecar.new", $sidecar or die "$sidecar: install: $!";
rename "$dmwrap.new",  $dmwrap  or die "$dmwrap: install: $!";

print STDERR <<END;
pvshim-converter: wrote qemu wrapper to $dmwrap
pvshim-converter: wrote sidecar to $sidecar
END

my $append = <<END;
builder='hvm'
type='hvm'
device_model_version='qemu-xen'
device_model_override='$dmwrap'
device_model_args_hvm=['-cdrom','$sidecar']
boot='c'
serial='pty'
END

if ($out ne '-') {
    open O, ">", "$out.tmp" or die "open output config temp: $out.tmp: $!\n";
} else {
    open O, ">&STDOUT" or die $!;
}

print O $indata, "\n", $append or die "write output: $!";
close O or die "close output: $!";

if ($out ne '-') {
    rename "$out.tmp", $out or die "install output: $!";
    print STDERR "pvshim-converter: wrote new guest config to $out\n";
} else {
    print STDERR "pvshim-converter: wrote new guest config to stdout\n";
}
