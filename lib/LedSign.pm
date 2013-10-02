package LedSign;
use Carp;
use strict;
use warnings;
use 5.005;
$LedSign::VERSION="0.01";
#
# Use Win32::Serial port on Windows otherwise, use Device::SerialPort
#
BEGIN 
{
   my $IS_WINDOWS = ($^O eq "MSWin32" or $^O eq "cygwin") ? 1 : 0;
   #
   if ($IS_WINDOWS) {
      eval "use Win32::SerialPort 0.14";
      die "$@\n" if ($@);
   } else {
      eval "use Device::SerialPort";
      die "$@\n" if ($@);
   }
}

sub new {
    my $that  = shift;
    my $class = ref($that) || $that;
    my(%params) = @_;
    my $this = {};
    bless $this, $class;
    $this->{tags}=();
    $this->_init(%params);
    return $this;
}
sub _connect {
    my $this=shift;
    my(%params)=@_;
    my $serial;
    my $port=$params{device};
    my $baudrate=$params{baudrate};
    my $IS_WINDOWS = ($^O eq "MSWin32" or $^O eq "cygwin") ? 1 : 0;
    if ($IS_WINDOWS) {
      $serial = new Win32::SerialPort ($port, 1);
    } else {
      $serial = new Device::SerialPort ($port, 1);
    }
    croak("Can't open serial port $port: $^E\n") unless ($serial);
    # set serial parameters
    $serial->baudrate($baudrate);
    $serial->parity('none');
    $serial->databits(8);
    $serial->stopbits(1);
    $serial->handshake('none');
    $serial->write_settings();
    return $serial;
}
sub slot {
    my $this=shift;
    my $slot;
    $slot=shift;
    my $return;
    if (!defined($slot)) {
         # a slot wasn't specified, so issue the next available
         for (@{$this->{slotrange}}) {
             if (!exists($this->{msgslots}{$_})) {
                 $this->{msgslots}->{$_}=1;
                 $return=$_;
                 last;
             }
         }
    } else {
        if (exists($this->{msgslots}->{$slot})) {
            croak("Slot [$slot] already in use\n");
        } else {
            $this->{msgslots}->{$slot}=1;
            $return=$slot;
        }
    }
    return $return;
}
#
# setkey and getkey to store and retrieve
# data using a key 
#
sub setkey {
    my $this=shift;
    my $object=shift;
    my $number=0;
    my $tag=sprintf("<i:%d>",$number);
    while (exists($this->{tags}{$tag})) {
        $tag=sprintf("<i:%d>",$number);
        $number++;
    }
    my $msgref=$object->{msgref};
    $this->{tags}{$tag}=$object->{msgref};
    return $tag;
}
sub getkey {
    my $this=shift;
    my $tag=shift;
    if (exists($this->{tags}{$tag})) {
        return $this->{tags}{$tag};
    } else {
        return "<error>";
    }
}

package LedSign::Factory;
sub new {
    my $that  = shift;
    my $class = ref($that) || $that;
    my(%params) = @_;
    my @objtypes=$params{objtypes};
    my $this = {};
    bless $this, $class;
    $this->{tags}=();
    $this->_init(%params);
    return $this;
}
sub _init {
    my( $package, $filename, $line ) = caller;
    die("Subclass must implement _init method for package [$package]");
}
sub add_object {
    my $this=shift;
    my $object=shift;
    my $objtype=$object->{objtype};
    my( $package, $filename, $line ) = caller;
    if (!defined($object->{objtype})) {
       croak("add_object: No object type supplied");
    }
    push(@{$this->{objects}{$object->{objtype}}},$object);
    my $count=$this->{$objtype."count"}++;
    $object->{number}=$count;
    return $count;
}
sub objects {
    my $this=shift;
    my $objtype=shift;
    if (!defined($objtype)) {
        croak("objects: No object type supplied");
    }
    if (!exists ($this->{objects}{$objtype})) {
        return ();
    }
    return(@{$this->{objects}{$objtype}});
}
1;