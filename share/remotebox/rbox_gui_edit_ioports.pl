# Edit Serial and Parallel Port Settings of a Guest
use strict;
use warnings;
our (%gui, %vmc);

sub setup_edit_dialog_ioports {
    my $port = &getsel_combo($gui{comboboxEditIOSelectedSerial}, 1);
    &addrow_log("Fetching I/O port settings for $vmc{Name}...");
    &busy_pointer($gui{dialogEdit}, 1);
    $gui{checkbuttonEditParallelEnable}->set_active(&bl(IParallelPort_getEnabled($vmc{IParallelPort})));
    $gui{tableEditParallel}->set_sensitive($gui{checkbuttonEditParallelEnable}->get_active()); # Ghost/Unghost other widgets based on parallel enabled
    $gui{entryEditParallelPath}->set_text(IParallelPort_getPath($vmc{IParallelPort}));
    my $pirq = IParallelPort_getIRQ($vmc{IParallelPort});
    my $pioport = sprintf('%X', IParallelPort_getIOBase($vmc{IParallelPort}));
    $gui{entryEditParallelIRQ}->set_text($pirq);
    $gui{entryEditParallelIO}->set_text($pioport);
    $gui{entryEditParallelIRQ}->set_sensitive(0);
    $gui{entryEditParallelIO}->set_sensitive(0);

    if ($pirq == 2 and uc($pioport) eq '3BC') { $gui{comboboxEditParallelPortNum}->set_active(0); }
    elsif ($pirq == 7 and uc($pioport) eq '378') { $gui{comboboxEditParallelPortNum}->set_active(1); }
    elsif ($pirq == 5 and uc($pioport) eq '278') { $gui{comboboxEditParallelPortNum}->set_active(2); }
    else {
        $gui{comboboxEditParallelPortNum}->set_active(3);
        $gui{entryEditParallelIRQ}->set_sensitive(1);
        $gui{entryEditParallelIO}->set_sensitive(1);
    }

    my $ISerialPort = IMachine_getSerialPort($vmc{IMachine}, $port);
    my $irq = ISerialPort_getIRQ($ISerialPort);
    my $ioport = sprintf('%X', ISerialPort_getIOBase($ISerialPort));
    my $mode = ISerialPort_getHostMode($ISerialPort);
    $gui{checkbuttonEditSerialEnable}->set_active(&bl(ISerialPort_getEnabled($ISerialPort)));
    $gui{tableEditSerial}->set_sensitive($gui{checkbuttonEditSerialEnable}->get_active()); # Ghost/Unghost other widgets based on serial enabled
    $gui{checkbuttonEditSerialPipe}->set_active(!&bl(ISerialPort_getServer($ISerialPort)));
    $gui{entryEditSerialPath}->set_text(ISerialPort_getPath($ISerialPort));
    $gui{entryEditSerialIRQ}->set_text($irq);
    $gui{entryEditSerialIO}->set_text($ioport);
    $gui{entryEditSerialIRQ}->set_sensitive(0);
    $gui{entryEditSerialIO}->set_sensitive(0);

    if ($irq == 4 and uc($ioport) eq '3F8') { $gui{comboboxEditSerialPortNum}->set_active(0); }
    elsif ($irq == 3 and uc($ioport) eq '2F8') { $gui{comboboxEditSerialPortNum}->set_active(1); }
    elsif ($irq == 4 and uc($ioport) eq '3E8') { $gui{comboboxEditSerialPortNum}->set_active(2); }
    elsif ($irq == 3 and uc($ioport) eq '2E8') { $gui{comboboxEditSerialPortNum}->set_active(3); }
    else {
        $gui{comboboxEditSerialPortNum}->set_active(4);
        $gui{entryEditSerialIRQ}->set_sensitive(1);
        $gui{entryEditSerialIO}->set_sensitive(1);
    }

    # Setting the pipe must come before setting the serial mode
    $gui{checkbuttonEditSerialPipe}->set_active(&bl(ISerialPort_getServer($ISerialPort)));

    if ($mode eq 'HostPipe') { $gui{comboboxEditSerialMode}->set_active(1); }
    elsif ($mode eq 'HostDevice') { $gui{comboboxEditSerialMode}->set_active(2); }
    elsif ($mode eq 'RawFile') { $gui{comboboxEditSerialMode}->set_active(3); }
    elsif ($mode eq 'TCP') { $gui{comboboxEditSerialMode}->set_active(4); }
    else { $gui{comboboxEditSerialMode}->set_active(0); }

    $gui{checkbuttonEditSerialPipe}->set_active(&bl(ISerialPort_getServer($ISerialPort)));

    &busy_pointer($gui{dialogEdit}, 0);
    &addrow_log('I/O Port settings complete.');
}

# Whether the serial port is enabled
sub serial_toggle {
    my ($widget) = @_;

    if ($vmc{SessionType} eq 'WriteLock') {
        my $state = $widget->get_active();
        my ($ISerialPort, $port) = &serial_callout();
        ISerialPort_setEnabled($ISerialPort, $state);
        $gui{tableEditSerial}->set_sensitive($state);
    }
}

# Whether a parallel port is enabled
sub parallel_toggle {
    my ($widget) = @_;

    if ($vmc{SessionType} eq 'WriteLock') {
        my $state = $widget->get_active();
        # Set path when first enabled, avoids VB chucking a no path specified warning
        if ($state and !$gui{entryEditParallelPath}->get_text()) {
            $gui{entryEditParallelPath}->set_text('/dev/parport0');
            &parallel_portpath($gui{entryEditParallelPath});
        }

        IParallelPort_setEnabled($vmc{IParallelPort}, $state);
        $gui{tableEditParallel}->set_sensitive($state);
    }
}

# The IRQ to use for the serial port
sub serial_irq {
    my ($widget, $focus) = @_;

    if ($vmc{SessionType} eq 'WriteLock') {
        my $irq = int($widget->get_text());
        $irq = 255 if ($irq > 255);
        $irq = 15 if ($irq > 15 and !$gui{checkbuttonEditSysAPIC}->get_active());
        my ($ISerialPort, $port) = &serial_callout();
        ISerialPort_setIRQ($ISerialPort, $irq);
    }

    return 0;
}

# The parallel port IRQ number
sub parallel_irq {
    if ($vmc{SessionType} eq 'WriteLock') {
        my $irq = int($gui{entryEditParallelIRQ}->get_text());
        $irq = 255 if ($irq > 255);
        $irq = 15 if ($irq > 15 and !$gui{checkbuttonEditSysAPIC}->get_active());
        IParallelPort_setIRQ($vmc{IParallelPort}, $irq);
    }

    return 0;
}

# The IO Port to use for the serial port
sub serial_ioport {
    my ($widget) = @_;

    if ($vmc{SessionType} eq 'WriteLock') {
        my $ioport = $widget->get_text();
        $ioport = 'FFFF' if (hex($ioport) > 65535);

        if ($ioport) {
            my ($ISerialPort, $port) = &serial_callout();
            ISerialPort_setIOBase($ISerialPort, hex($ioport));
        }
    }

    return 0;
}

# The parallel port IO PORT
sub parallel_ioport {
    if ($vmc{SessionType} eq 'WriteLock') {
        my $ioport = $gui{entryEditParallelIO}->get_text();
        $ioport = 'FFFF' if (hex($ioport) > 65535);
        if ($ioport) { IParallelPort_setIOBase($vmc{IParallelPort}, hex($ioport)); }
    }

    return 0;
}

# The serial port mode
sub serial_portmode {
    my ($widget) = @_;
    my $vhost = &vhost();

    # For all serial modes except disconnected, it needs a path set
    # before it can be activated, otherwise it errors. We try to do our best with
    # defaults here
    if ($vmc{SessionType} eq 'WriteLock') {
        my ($ISerialPort, $port) = &serial_callout();
        my $mode = &getsel_combo($widget, 0);

        if ($mode eq 'RawFile') {
            $$vhost{os} =~ m/^WINDOWS/i ? $gui{entryEditSerialPath}->set_text("\%temp\%\\raw-$vmc{Name}-ser" . ($port + 1))
                                        : $gui{entryEditSerialPath}->set_text("/tmp/raw-$vmc{Name}-ser" . ($port + 1));
        }
        elsif ($mode eq 'HostPipe') {
            $$vhost{os} =~ m/^WINDOWS/i ? $gui{entryEditSerialPath}->set_text("\\\\.\\pipe\\pipe-$vmc{Name}-ser" . ($port + 1))
                                        : $gui{entryEditSerialPath}->set_text("/tmp/pipe-$vmc{Name}-ser" . ($port + 1));
        }
        elsif ($mode eq 'HostDevice') {
            my $device = '/dev/null';
            if ($$vhost{os} =~ m/Linux/i) { $device = '/dev/ttyS' . $port; }
            elsif ($$vhost{os} =~ m/WINDOWS/i) { $device = "COM" . ($port + 1) . ':'; }
            elsif ($$vhost{os} =~ m/Darwin/i) { $device = '/dev/null'; }
            elsif ($$vhost{os} =~ m/Solaris/i) { $device = '/dev/cua'; }
            elsif ($$vhost{os} =~ m/FreeBSD/i) { $device = '/dev/cuad' . $port; }
            $gui{entryEditSerialPath}->set_text($device);
        }
        elsif ($mode eq 'TCP') { $gui{entryEditSerialPath}->set_text('65000'); }

        $gui{entryEditSerialPath}->signal_emit('activate');
        ISerialPort_setHostMode($ISerialPort, &getsel_combo($widget, 0));
    }
}

# Whether to automatically create a PIPE when opening the serial port
sub serial_createpipe {
    my ($widget) = @_;

    if ($vmc{SessionType} eq 'WriteLock') {
        my ($ISerialPort, $port) = &serial_callout();
        ISerialPort_setServer($ISerialPort, !$widget->get_active());
    }
}

# The serial port path
sub serial_portpath {
    my ($widget) = @_;

    if ($vmc{SessionType} eq 'WriteLock') {

        my $path = $widget->get_text();
        if ($path) {
            my ($ISerialPort, $port) = &serial_callout();
            ISerialPort_setPath($ISerialPort, $path);
        }
    }

    return 0;
}

# The parallel port path
sub parallel_portpath {
    if ($vmc{SessionType} eq 'WriteLock') {
        my $path = $gui{entryEditParallelPath}->get_text();
        if ($path) { IParallelPort_setPath($vmc{IParallelPort}, $path); }
    }

    return 0;
}

# The COM port number to use for the serial port
sub serial_portnum {
    my ($widget) = @_;

    if ($vmc{SessionType} eq 'WriteLock') {
        my $portnum = &getsel_combo($widget, 0);
        my ($ISerialPort, $port) = &serial_callout();

        if ($portnum eq 'COM1') {
            $gui{entryEditSerialIRQ}->set_text('4');
            $gui{entryEditSerialIO}->set_text('3F8');
        }
        elsif ($portnum eq 'COM2') {
            $gui{entryEditSerialIRQ}->set_text('3');
            $gui{entryEditSerialIO}->set_text('2F8');
        }
        elsif ($portnum eq 'COM3') {
            $gui{entryEditSerialIRQ}->set_text('4');
            $gui{entryEditSerialIO}->set_text('3E8');
        }
        elsif ($portnum eq 'COM4') {
            $gui{entryEditSerialIRQ}->set_text('3');
            $gui{entryEditSerialIO}->set_text('2E8');
        }

        if ($portnum ne 'Custom') {
            &serial_irq($gui{entryEditSerialIRQ});
            &serial_ioport($gui{entryEditSerialIO});
            $gui{entryEditSerialIRQ}->set_sensitive(0);
            $gui{entryEditSerialIO}->set_sensitive(0);
        }
        else {
            $gui{entryEditSerialIRQ}->set_sensitive(1);
            $gui{entryEditSerialIO}->set_sensitive(1);
        }
    }
}

# The LPT port number to use
sub parallel_portnum {
    my ($widget) = @_;

    if ($vmc{SessionType} eq 'WriteLock') {
        my $portnum = &getsel_combo($widget, 0);

        if ($portnum eq 'LPT1') {
            $gui{entryEditParallelIRQ}->set_text('2');
            $gui{entryEditParallelIO}->set_text('3BC');
        }
        elsif ($portnum eq 'LPT2') {
            $gui{entryEditParallelIRQ}->set_text('7');
            $gui{entryEditParallelIO}->set_text('378');
        }
        elsif ($portnum eq 'LPT3') {
            $gui{entryEditParallelIRQ}->set_text('5');
            $gui{entryEditParallelIO}->set_text('278');
        }

        if ($portnum ne 'Custom') {
            &parallel_irq($gui{entryEditParallelIRQ}, 0);
            &parallel_ioport($gui{entryEditParallelIO}, 0);
            $gui{entryEditParallelIRQ}->set_sensitive(0);
            $gui{entryEditParallelIO}->set_sensitive(0);
        }
        else {
            $gui{entryEditParallelIRQ}->set_sensitive(1);
            $gui{entryEditParallelIO}->set_sensitive(1);
        }
    }

}

# Gets the current working serial port number
sub serial_callout {
    my $port = &getsel_combo($gui{comboboxEditIOSelectedSerial}, 1);

    if ($vmc{SessionType} eq 'WriteLock') {
        my $ISerialPort = IMachine_getSerialPort($vmc{IMachine}, $port);
        return $ISerialPort, $port;
    }
}

1;
