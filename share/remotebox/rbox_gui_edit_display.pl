# Edit Display Settings of a Guest
use strict;
use warnings;
our (%gui, %vmc);

# Initialise the display page
sub setup_edit_dialog_display() {
    my $vhost = &vhost();
    &addrow_log("Fetching display settings for $vmc{Name}...");
    &busy_pointer($gui{dialogEdit}, 1);

    if (IMachine_getGraphicsControllerType($vmc{IMachine}) eq 'VMSVGA') { $gui{comboboxEditDispVGA}->set_active(1); }
    else { $gui{comboboxEditDispVGA}->set_active(0); }

    $gui{spinbuttonEditDispVidMem}->set_range($$vhost{minguestvram}, $$vhost{maxguestvram});
    $gui{spinbuttonEditDispVidMem}->set_value(IMachine_getVRAMSize($vmc{IMachine}));
    $gui{spinbuttonEditDispMonitor}->set_range(1, $$vhost{maxmonitors});
    $gui{spinbuttonEditDispMonitor}->set_value(IMachine_getMonitorCount($vmc{IMachine}));
    $gui{spinbuttonEditDispCaptureFPS}->set_value(IMachine_getVideoCaptureFPS($vmc{IMachine}));
    $gui{spinbuttonEditDispCaptureQuality}->set_value(IMachine_getVideoCaptureRate($vmc{IMachine}));
    $gui{spinbuttonEditDispAuthTime}->set_value(IVRDEServer_getAuthTimeout($vmc{IVRDEServer}));
    $gui{checkbuttonEditDisp3D}->set_active(&bl(IMachine_getAccelerate3DEnabled($vmc{IMachine})));
    $gui{checkbuttonEditDisp2D}->set_active(&bl(IMachine_getAccelerate2DVideoEnabled($vmc{IMachine})));
    $gui{checkbuttonEditDispServer}->set_active(&bl(IVRDEServer_getEnabled($vmc{IVRDEServer})));
    $gui{checkbuttonEditDispCapture}->set_active(&bl(IMachine_getVideoCaptureEnabled($vmc{IMachine})));
    $gui{tableEditDispRemote}->set_sensitive($gui{checkbuttonEditDispServer}->get_active()); # Ghost/Unghost other widgets based on server enabled
    $gui{tableEditDispCapture}->set_sensitive($gui{checkbuttonEditDispCapture}->get_active()) if ($vmc{SessionType} eq 'WriteLock'); # Ghost/Unghost other widgets based on capture enabled
    $gui{entryEditDispPort}->set_text(IVRDEServer_getVRDEProperty($vmc{IVRDEServer}, 'TCP/Ports'));
    $gui{entryEditDispCapturePath}->set_text(IMachine_getVideoCaptureFile($vmc{IMachine}));
    $gui{checkbuttonEditDispMultiple}->set_active(&bl(IVRDEServer_getAllowMultiConnection($vmc{IVRDEServer})));
    # Bit hacky to work around what appears to be a bug in VB 4.0.x
    my $dispqual = IVRDEServer_getVRDEProperty($vmc{IVRDEServer}, 'VideoChannel/Quality');
    if (!$dispqual) { IVRDEServer_setVRDEProperty($vmc{IVRDEServer}, 'VideoChannel/Quality', 75); }
    $gui{spinbuttonEditDispQuality}->set_value(int(IVRDEServer_getVRDEProperty($vmc{IVRDEServer}, 'VideoChannel/Quality')));
    &combobox_set_active_text($gui{comboboxDispAuthMeth}, IVRDEServer_getAuthType($vmc{IVRDEServer}));

    my $w = IMachine_getVideoCaptureWidth($vmc{IMachine});
    my $h = IMachine_getVideoCaptureHeight($vmc{IMachine});

    # Setting the combobox will automatically set the associated spinboxes
    if ($w == 320 and $h == 200) { $gui{comboboxEditDispCaptureSize}->set_active(1); }
    elsif ($w == 640 and $h == 480) { $gui{comboboxEditDispCaptureSize}->set_active(2); }
    elsif ($w == 720 and $h == 400) { $gui{comboboxEditDispCaptureSize}->set_active(3); }
    elsif ($w == 720 and $h == 480) { $gui{comboboxEditDispCaptureSize}->set_active(4); }
    elsif ($w == 800 and $h == 600) { $gui{comboboxEditDispCaptureSize}->set_active(5); }
    elsif ($w == 1024 and $h == 768) { $gui{comboboxEditDispCaptureSize}->set_active(6); }
    elsif ($w == 1280 and $h == 720) { $gui{comboboxEditDispCaptureSize}->set_active(7); }
    elsif ($w == 1280 and $h == 800) { $gui{comboboxEditDispCaptureSize}->set_active(8); }
    elsif ($w == 1280 and $h == 960) { $gui{comboboxEditDispCaptureSize}->set_active(9); }
    elsif ($w == 1280 and $h == 1024) { $gui{comboboxEditDispCaptureSize}->set_active(10); }
    elsif ($w == 1366 and $h == 768) { $gui{comboboxEditDispCaptureSize}->set_active(11); }
    elsif ($w == 1440 and $h == 900) { $gui{comboboxEditDispCaptureSize}->set_active(12); }
    elsif ($w == 1440 and $h == 1080) { $gui{comboboxEditDispCaptureSize}->set_active(13); }
    elsif ($w == 1600 and $h == 900) { $gui{comboboxEditDispCaptureSize}->set_active(14); }
    elsif ($w == 1680 and $h == 1050) { $gui{comboboxEditDispCaptureSize}->set_active(15); }
    elsif ($w == 1600 and $h == 1200) { $gui{comboboxEditDispCaptureSize}->set_active(16); }
    elsif ($w == 1920 and $h == 1080) { $gui{comboboxEditDispCaptureSize}->set_active(17); }
    elsif ($w == 1920 and $h == 1200) { $gui{comboboxEditDispCaptureSize}->set_active(18); }
    elsif ($w == 1920 and $h == 1440) { $gui{comboboxEditDispCaptureSize}->set_active(19); }
    else {
        $gui{comboboxEditDispCaptureSize}->set_active(0);
        $gui{spinbuttonEditDispCaptureSizeW}->set_value($w);
        $gui{spinbuttonEditDispCaptureSizeH}->set_value($h);
    }

    &busy_pointer($gui{dialogEdit}, 0);
    &addrow_log('Display settings complete.');
}

# Set whether 2D acceleration is enabled
sub disp_2D { IMachine_setAccelerate2DVideoEnabled($vmc{IMachine}, $gui{checkbuttonEditDisp2D}->get_active()); }

# Set whether 3D accelerator is enabled.
sub disp_3D { IMachine_setAccelerate3DEnabled($vmc{IMachine}, $gui{checkbuttonEditDisp3D}->get_active()); }

# Set the RDP authentication type
sub disp_RDPauth { IVRDEServer_setAuthType($vmc{IVRDEServer}, &getsel_combo($gui{comboboxDispAuthMeth}, 0)); }

# Set the virtual VGA card type
sub disp_virtual_VGA { if ($vmc{SessionType} eq 'WriteLock') { IMachine_setGraphicsControllerType($vmc{IMachine}, &getsel_combo($gui{comboboxEditDispVGA}, 0)); } }

# Set whether multiple RDP logins are allowed
sub disp_RDPmulti {
    # Avoid triggering if not in WriteLock mode. Cannot be changed when guest is running
    IVRDEServer_setAllowMultiConnection($vmc{IVRDEServer}, $gui{checkbuttonEditDispMultiple}->get_active()) if ($vmc{SessionType} eq 'WriteLock');
}

# Set the amount of video memory
sub disp_vidmem {
    if ($vmc{SessionType} eq 'WriteLock') {
        IMachine_setVRAMSize($vmc{IMachine}, int($gui{spinbuttonEditDispVidMem}->get_value_as_int()));
        return 0; # Must return this value for the signal used.
    }
}

# Set the number of virtual monitors
sub disp_monitors {
    if ($vmc{SessionType} eq 'WriteLock') {
    IMachine_setMonitorCount($vmc{IMachine}, int($gui{spinbuttonEditDispMonitor}->get_value_as_int()));
    return 0; # Must return this value for the signal used.
    }
}

# Set whether the RDP server is enabled or not
sub disp_toggleRDP {
    my $state = $gui{checkbuttonEditDispServer}->get_active();
    IVRDEServer_setEnabled($vmc{IVRDEServer}, $state);
    $gui{tableEditDispRemote}->set_sensitive($state);
}

sub disp_RDPtime {
    IVRDEServer_setAuthTimeout($vmc{IVRDEServer}, $gui{spinbuttonEditDispAuthTime}->get_value_as_int());
    return 0;
}

sub disp_RDPport {
    my $ports = $gui{entryEditDispPort}->get_text();
    IVRDEServer_setVRDEProperty($vmc{IVRDEServer}, 'TCP/Ports', $ports) if ($ports);
    return 0;
}

sub disp_quality {
    IVRDEServer_setVRDEProperty($vmc{IVRDEServer}, 'VideoChannel/Quality', $gui{spinbuttonEditDispQuality}->get_value_as_int());
    return 0; # Must return this value for the signal used.
}

sub disp_toggleCapture {
    my $state = $gui{checkbuttonEditDispCapture}->get_active();
    IMachine_setVideoCaptureEnabled($vmc{IMachine}, $state);
    # Don't enable other widgets unless in WriteLock Mode
    $gui{tableEditDispCapture}->set_sensitive($state) if ($vmc{SessionType} eq 'WriteLock');
}

# If the combobox changes, update the associated spinboxes
sub disp_capturesize {
    my ($widget) = @_;
    my ($w, $h) = (&getsel_combo($widget,1), &getsel_combo($widget,2));
    unless ($w < 17 and $h < 17) { # Min width/height is 16, user defined is 0/0
        $gui{spinbuttonEditDispCaptureSizeW}->set_value($w);
        $gui{spinbuttonEditDispCaptureSizeH}->set_value($h);
    }
}

# Save the preferred capture width
sub disp_capturesizew {
    # Avoid triggering if not in WriteLock mode. Cannot be changed when guest is running
    IMachine_setVideoCaptureWidth($vmc{IMachine}, $gui{spinbuttonEditDispCaptureSizeW}->get_value_as_int()) if ($vmc{SessionType} eq 'WriteLock');
    return 0;
}

# Save the preferred capture height
sub disp_capturesizeh {
    # Avoid triggering if not in WriteLock mode. Cannot be changed when guest is running
    IMachine_setVideoCaptureHeight($vmc{IMachine}, $gui{spinbuttonEditDispCaptureSizeH}->get_value_as_int()) if ($vmc{SessionType} eq 'WriteLock');
    return 0;
}

# The number of FPS to capture
sub disp_capturefps {
    # Avoid triggering if not in WriteLock mode. Cannot be changed when guest is running
    IMachine_setVideoCaptureFPS($vmc{IMachine}, $gui{spinbuttonEditDispCaptureFPS}->get_value_as_int())  if ($vmc{SessionType} eq 'WriteLock');
    return 0;
}

# The quality of the recorded video in kbps
sub disp_capturequality {
    # Avoid triggering if not in WriteLock mode. Cannot be changed when guest is running
    IMachine_setVideoCaptureRate($vmc{IMachine}, $gui{spinbuttonEditDispCaptureQuality}->get_value_as_int()) if ($vmc{SessionType} eq 'WriteLock');
    return 0;
}

sub sys_capturepath {
    # Avoid triggering if not in WriteLock mode. Cannot be changed when guest is running
    IMachine_setVideoCaptureFile($vmc{IMachine}, $gui{entryEditDispCapturePath}->get_text()) if ($vmc{SessionType} eq 'WriteLock');
    return 0;
}

1;
