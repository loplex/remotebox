# The Remote Display page of the Display Settings
use strict;
use warnings;
our (%gui, %vmc);

sub init_edit_disp_remote {
    &busy_pointer($gui{dialogEdit}, 1);
    $gui{checkbuttonEditDispServer}->set_active(&bl(IVRDEServer_getEnabled($vmc{IVRDEServer})));
    $gui{tableEditDispRemote}->set_sensitive($gui{checkbuttonEditDispServer}->get_active()); # Ghost/Unghost other widgets based on server enabled
    $gui{spinbuttonEditDispAuthTime}->set_value(IVRDEServer_getAuthTimeout($vmc{IVRDEServer}));
    $gui{entryEditDispPort}->set_text(IVRDEServer_getVRDEProperty($vmc{IVRDEServer}, 'TCP/Ports'));
    $gui{checkbuttonEditDispMultiple}->set_active(&bl(IVRDEServer_getAllowMultiConnection($vmc{IVRDEServer})));
    #FIXME (Is this still the case?) Bit hacky to work around what appears to be a bug in VB 4.0.x
    my $dispqual = IVRDEServer_getVRDEProperty($vmc{IVRDEServer}, 'VideoChannel/Quality');
    if (!$dispqual) { IVRDEServer_setVRDEProperty($vmc{IVRDEServer}, 'VideoChannel/Quality', 75); }
    $gui{spinbuttonEditDispQuality}->set_value(int(IVRDEServer_getVRDEProperty($vmc{IVRDEServer}, 'VideoChannel/Quality')));
    &combobox_set_active_text($gui{comboboxDispAuthMeth}, IVRDEServer_getAuthType($vmc{IVRDEServer}), 0);
    &busy_pointer($gui{dialogEdit}, 0);
}

# Set the RDP authentication type
sub disp_rem_auth { IVRDEServer_setAuthType($vmc{IVRDEServer}, &getsel_combo($gui{comboboxDispAuthMeth}, 0)); }

# Set whether multiple RDP logins are allowed
sub disp_rem_multi {
    # Avoid triggering if not in WriteLock mode. Cannot be changed when guest is running
    IVRDEServer_setAllowMultiConnection($vmc{IVRDEServer}, $gui{checkbuttonEditDispMultiple}->get_active()) if ($vmc{SessionType} eq 'WriteLock');
}

# Set whether the RDP server is enabled or not
sub disp_toggleRemote {
    my $state = $gui{checkbuttonEditDispServer}->get_active();
    IVRDEServer_setEnabled($vmc{IVRDEServer}, $state);
    $gui{tableEditDispRemote}->set_sensitive($state);
}

# Authentication timeout for the RDP server
sub disp_rem_timeout {
    IVRDEServer_setAuthTimeout($vmc{IVRDEServer}, $gui{spinbuttonEditDispAuthTime}->get_value_as_int());
    return 0;
}

# TCP Ports to use for the RDP / VNC server
sub disp_rem_ports {
    my $ports = $gui{entryEditDispPort}->get_text();
    IVRDEServer_setVRDEProperty($vmc{IVRDEServer}, 'TCP/Ports', $ports) if ($ports);
    return 0;
}

# Quality of the RDP video steam
sub disp_rem_quality {
    IVRDEServer_setVRDEProperty($vmc{IVRDEServer}, 'VideoChannel/Quality', $gui{spinbuttonEditDispQuality}->get_value_as_int());
    return 0; # Must return this value for the signal used.
}

1;
