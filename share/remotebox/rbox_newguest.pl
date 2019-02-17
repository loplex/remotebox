# Creating a new guest
use strict;
use warnings;
our (%gui, %signal, %prefs);

sub show_dialog_newguest {
    my $vhost = &vhost();
    my ($osfam, $osver) = &osfamver();
    $gui{checkbuttonNewNewHD}->set_active(1);
    $gui{comboboxNewNewFormat}->set_active(0);
    $gui{radiobuttonNewDynamic}->set_sensitive(1);
    $gui{radiobuttonNewFixed}->set_sensitive(1);
    $gui{radiobuttonNewSplit}->set_sensitive(0);
    $gui{entryNewName}->set_text('NewGuest' . int(rand(9999)));
    $gui{spinbuttonNewMemory}->set_range($$vhost{minguestram}, $$vhost{memsize});
    $gui{spinbuttonNewNewHDSize}->set_range($$vhost{minhdsizemb}, $$vhost{maxhdsizemb});
    $gui{comboboxNewOSFam}->signal_handler_block($signal{fam}); # Block to avoid signal emission when changing
    $gui{comboboxNewOSVer}->signal_handler_block($signal{ver});
    $gui{liststoreNewOSFam}->clear();
    $gui{liststoreNewOSVer}->clear();
    $gui{liststoreNewChooseHD}->clear();

    foreach my $fam (sort {
                            if    ($$osfam{$a}{description} =~ m/Other/) { return 1; }
                            elsif ($$osfam{$b}{description} =~ m/Other/) { return -1; }
                            else  { return lc($$osfam{$a}{description}) cmp lc($$osfam{$b}{description}) }
                          } keys %{$osfam}) {

        my $iter = $gui{liststoreNewOSFam}->append();
        $gui{liststoreNewOSFam}->set($iter, 0, "$$osfam{$fam}{description}", 1, $fam, 2, $$osfam{$fam}{icon});
        $gui{comboboxNewOSFam}->set_active_iter($iter) if ($fam eq 'Windows');
    }

    my $IMediumRef = &get_all_media('HardDisk');

    if (keys(%$IMediumRef) > 0) {
        foreach my $hd (sort { lc($$IMediumRef{$a}) cmp lc($$IMediumRef{$b}) } (keys(%$IMediumRef))) {
            my $iter = $gui{liststoreNewChooseHD}->append();
            $gui{liststoreNewChooseHD}->set($iter, 0, $$IMediumRef{$hd}, 1, $hd);
        }

        $gui{comboboxNewChooseHD}->set_active(0);
        $gui{radiobuttonNewExistingHD}->set_sensitive(1);
    }
    else { $gui{radiobuttonNewExistingHD}->set_sensitive(0); };

    $gui{comboboxNewOSFam}->signal_handler_unblock($signal{fam});
    $gui{comboboxNewOSVer}->signal_handler_unblock($signal{ver});
    $gui{comboboxNewOSFam}->signal_emit('changed'); # Force update of other fields based on OS
    $gui{comboboxNewOSVer}->signal_emit('changed'); # Force update of other fields based on OS

    do {
        my $response = $gui{dialogNew}->run;

        if ($response eq 'ok') {
            # Other entries do not require validation
            if (!$gui{entryNewName}->get_text()) { &show_err_msg('invalidname'); }
            else {
                $gui{dialogNew}->hide;

                my %new = (name => $gui{entryNewName}->get_text(),
                           fam  => &getsel_combo($gui{comboboxNewOSFam}, 1),
                           ver  => &getsel_combo($gui{comboboxNewOSVer}, 1),
                           mem  => $gui{spinbuttonNewMemory}->get_value_as_int());

                my ($IMachine, $dvdctrname, $hdctrname, $floppyctrname) = &create_new_guest(\%new);

                if ($gui{checkbuttonNewNewHD}->get_active() == 1) {

                    if ($IMachine) {
                        my $sref = &get_session($IMachine);

                        if ($$sref{Type} eq 'WriteLock') {
                            my $IMediumHD;

                            if ($gui{radiobuttonNewNewHD}->get_active()) {
                                my %newhd = (diskname   => $new{name}, # Use guest name as basis for disk
                                             size       => $gui{spinbuttonNewNewHDSize}->get_value_as_int() * 1048576,
                                             allocation => 'Standard', # Standard == Dynamic Allocation
                                             imgformat  => &getsel_combo($gui{comboboxNewNewFormat}, 1),
                                             location   => &rcatdir($$vhost{machinedir}, $new{name}));

                                if ($gui{radiobuttonNewFixed}->get_active()) { $newhd{allocation} = 'Fixed'; }
                                elsif ($gui{radiobuttonNewSplit}->get_active()) { $newhd{allocation} = 'VmdkSplit2G'; }
                                $IMediumHD = &create_new_hd(\%newhd, $gui{windowMain});
                            }
                            else { $IMediumHD = &getsel_combo($gui{comboboxNewChooseHD}, 1); }

                            my $IStorCtrHD = IMachine_getStorageControllerByName($$sref{IMachine}, $hdctrname);
                            my %hdaddress = &get_free_deviceport($$sref{IMachine}, $IStorCtrHD);
                            IMachine_attachDevice($$sref{IMachine}, $hdctrname, $hdaddress{portnum}, $hdaddress{devnum}, 'HardDisk', $IMediumHD) if ($IMediumHD);
                            my $IStorCtrDVD = IMachine_getStorageControllerByName($$sref{IMachine}, $dvdctrname); # Attach Empty CD/DVD Device
                            my %dvdaddress = &get_free_deviceport($$sref{IMachine}, $IStorCtrDVD);
                            IMachine_attachDevice($$sref{IMachine}, $dvdctrname, $dvdaddress{portnum}, $dvdaddress{devnum}, 'DVD', '');

                            if ($floppyctrname) {
                                my $IStorCtrFloppy = IMachine_getStorageControllerByName($$sref{IMachine}, $floppyctrname);
                                my %floppyaddress = &get_free_deviceport($$sref{IMachine}, $IStorCtrFloppy);
                                IMachine_attachDevice($$sref{IMachine}, $floppyctrname, $floppyaddress{portnum}, $floppyaddress{devnum}, 'Floppy', '');
                            }

                            IMachine_saveSettings($$sref{IMachine});
                        }

                        ISession_unlockMachine($$sref{ISession}) if (ISession_getState($$sref{ISession}) eq 'Locked');
                    }
                    else { &show_err_msg('createguest', " ($new{name})"); }
                }

                &fill_list_guest();
            }
        }
        else { $gui{dialogNew}->hide; }

    } until (!$gui{dialogNew}->visible());
}

# We have some serious limitations as the moment when setting the clone
# options. The vboxservice.pm doesn't seem to be able to handle the
# passing of arrays which means when creating a clone we can only set
# one option at creation. Ie we can't have Linked and KeepALLMACs set.
# Need to find a work around.
sub show_dialog_clone {
    my $gref = &getsel_list_guest();
    $gui{entryCloneName}->set_text($$gref{Name} . ' Clone' . int(rand(9999)));
    $gui{comboboxCloneType}->set_active(0);
    $gui{checkbuttonCloneNewMACs}->set_active(1);

    do {
        my $response = $gui{dialogClone}->run;

        if ($response eq 'ok') {
            # No validation needed for other entries
            if (!$gui{entryCloneName}->get_text()) { &show_err_msg('invalidname'); }
            else {
                $gui{dialogClone}->hide;
                my $clonetype = 'Full'; # Defaults to Full
                my $newmacs = $gui{checkbuttonCloneNewMACs}->get_active();

                if ($gui{comboboxCloneType}->get_active() == 2) { $clonetype = 'Link'; }
                elsif ($gui{comboboxCloneType}->get_active() == 1) { $clonetype = 'Current'; }

                &create_new_clone($gref, $gui{entryCloneName}->get_text(), $clonetype, $newmacs);
                &fill_list_guest();
            }
        }
        else { $gui{dialogClone}->hide; }

    } until (!$gui{dialogClone}->visible());
}

# Determines the next free port number and device number on a controller. If
# there isn't one, then a new one will be created, provided the controller is
# not at its maximum. If it is -1 is returned for the port and device numbers
sub get_free_deviceport {
    # !!Be careful about portnum versus portcount!! Eg ports 0 to 7 is a portcount of 8
    my ($IMachine, $IStorCtr) = @_;

    # A device address is made up of PortNumber then DeviceNumber
    my %address = (portnum => -1,
                   devnum  => -1);

    my @usedaddress;
    my @IMediumAttachment = IMachine_getMediumAttachmentsOfController($IMachine, IStorageController_getName($IStorCtr));
    my $portnum_hi = (IStorageController_getPortCount($IStorCtr)) - 1;
    my $devnum_hi = (IStorageController_getMaxDevicesPerPortCount($IStorCtr)) - 1;

    # Populate the used addresses.
    foreach my $attach (@IMediumAttachment) { $usedaddress[$$attach{device}][$$attach{port}] = $attach; }

    # Discover free ports/devices
    foreach my $devnum (0..$devnum_hi) {
        last if ($address{devnum} != -1); # Found a free address

        foreach my $portnum (0..$portnum_hi) {
            next if ($usedaddress[$devnum][$portnum]); # Its used. Try next one
            $address{devnum} = $devnum;
            $address{portnum} = $portnum;
            last;
        }
    }

    # If we haven't found a free address, try to create a new one
    if ($address{portnum} == -1) {
        my $portnum_max = IStorageController_getMaxPortCount($IStorCtr) - 1;

        if ($portnum_hi < $portnum_max) {
            $portnum_hi++; # Increase the max portnumber
            IStorageController_setPortCount($IStorCtr, $portnum_hi + 1); # Portcount is always +1 over the highest port number
            $address{portnum} = $portnum_hi;
            $address{devnum} = 0;
        }
    }

    return %address;
}

sub create_new_clone {
    my $vhost = &vhost();
    my ($srcgref, $clonename, $clonetype, $newmacs) = @_;

    # We create a new 'empty' guest
    my $cloneIMachine = IVirtualBox_createMachine($gui{websn}, '', $clonename, '', $$srcgref{Osid}, 'UUID 00000000-0000-0000-0000-000000000000', '');
    my $IProgress;

    if ($clonetype eq 'Link') { # Is cancellable
        # Force newmacs to be 0 because they get regenerated automatically anyway (whether we like it or not)
        $newmacs = 0;
        # Linked clones require a snapshot of the source to be taken first. The IMachine must be of that snapshot
        &take_snapshot("Base for $$srcgref{Name} and $clonename", "Snapshot automatically taken when cloning $$srcgref{Name} to $clonename");
        my $snapIMachine = ISnapshot_getMachine(IMachine_getCurrentSnapshot($$srcgref{IMachine}));
        $IProgress = IMachine_cloneTo($snapIMachine, $cloneIMachine, 'MachineState', 'Link');
    }
    # For some reason if you don't specify an option it always assumes linked so we'll use KeepAllMacs then regenerate them
    elsif ($clonetype eq 'Current') { $IProgress = IMachine_cloneTo($$srcgref{IMachine}, $cloneIMachine, 'MachineState', 'KeepAllMACs'); }
    else { $IProgress = IMachine_cloneTo($$srcgref{IMachine}, $cloneIMachine, 'AllStates', 'KeepAllMACs'); }

    &show_progress_window($IProgress, 'Cloning Guest', $gui{img}{ProgressClone}) if ($IProgress); # MUST NOT USE $cloneIMachine until progress is complete, otherwise it waits

    if (IProgress_getCanceled($IProgress) eq 'true') {
        &addrow_log('Cancelled guest clone');
        IManagedObjectRef_release($cloneIMachine);
        $cloneIMachine = undef;
    }
    else {
        # Regenerate the MACs if the option has been selected
        if ($newmacs) {
            foreach (0..($$vhost{maxnet}-1)) {
                my $INetworkAdapter = IMachine_getNetworkAdapter($cloneIMachine, $_);
                INetworkAdapter_setMACAddress($INetworkAdapter, IHost_generateMACAddress($$vhost{IHost}));
            }
        }

        IMachine_saveSettings($cloneIMachine);
        IVirtualBox_registerMachine($gui{websn}, $cloneIMachine);
        &addrow_log("Cloned $$srcgref{Name} to $clonename");
    }
}

# Creates a new guest
sub create_new_guest {
    my ($newref) = @_;
    my $osver = &osver();
    my $vhost = &vhost();
    my %os = %{ $$osver{$$newref{ver}} };
    my $dvdctrname = $os{recommendedDVDStorageBus};
    my $hdctrname = $os{recommendedHDStorageBus};
    my $floppyctrname = 'Floppy' if ($os{recommendedFloppy} eq 'true');
    my $IMachine = IVirtualBox_createMachine($gui{websn}, '', $$newref{name}, '', $$newref{ver}, 'UUID 00000000-0000-0000-0000-000000000000', '');

    if ($IMachine) {
        # We would like to use this instead of parsing all the defaults but it's
        # horribly broken in VB
        # IMachine_applyDefaults($IMachine);
        my $IVRDEServer = IMachine_getVRDEServer($IMachine);
        my $IBIOSSettings = IMachine_getBIOSSettings($IMachine);
        my $IAudioAdapter = IMachine_getAudioAdapter($IMachine);
        IMachine_setChipsetType($IMachine, $os{recommendedChipset});
        IBIOSSettings_setIOAPICEnabled($IBIOSSettings, &bl($os{recommendedIOAPIC}));
        IMachine_setCPUProperty($IMachine, 'PAE', &bl($os{recommendedPAE}));
        IMachine_setHWVirtExProperty($IMachine, 'Enabled', 1);
        IMachine_setHPETEnabled($IMachine, &bl($os{recommendedHPET}));
        IMachine_setVRAMSize($IMachine, $os{recommendedVRAM});
        IMachine_setFirmwareType($IMachine, $os{recommendedFirmware});
        IMachine_setMemorySize($IMachine, $$newref{mem});
        IMachine_setRTCUseUTC($IMachine, &bl($os{recommendedRTCUseUTC}));
        IMachine_addUSBController($IMachine, 'OHCI', 'OHCI') if (&bl($os{recommendedUSB}));
        IMachine_addUSBController($IMachine, 'EHCI', 'EHCI') if (&bl($os{recommendedUSB}));
        IMachine_setPointingHIDType($IMachine, 'USBMouse') if ($os{recommendedUSBHID} eq 'true');
        IMachine_setPointingHIDType($IMachine, 'USBTablet') if ($os{recommendedUSBTablet} eq 'true');
        IMachine_setAccelerate2DVideoEnabled($IMachine, $os{recommended2DVideoAcceleration});
        IAudioAdapter_setAudioController($IAudioAdapter, $os{recommendedAudioController});
        IAudioAdapter_setAudioDriver($IAudioAdapter, 'Null');
        IAudioAdapter_setEnabled($IAudioAdapter, 1);
        IAudioAdapter_setEnabledOut($IAudioAdapter, 1);

        my $IStorCtrFloppy = IMachine_addStorageController($IMachine, $floppyctrname, 'Floppy') if ($floppyctrname);
        my $IStorCtrDVD = IMachine_addStorageController($IMachine, $dvdctrname, $os{recommendedDVDStorageBus});
        IStorageController_setControllerType($IStorCtrDVD, $os{recommendedDVDStorageController});
        IStorageController_setPortCount($IStorCtrDVD, IStorageController_getMinPortCount($IStorCtrDVD)); # Controllers have all ports on by default. Set to the minimum

        if ($os{recommendedHDStorageBus} ne $os{recommendedDVDStorageBus}) {
            my $IStorCtrHD = IMachine_addStorageController($IMachine, $hdctrname, $os{recommendedHDStorageBus});
            IStorageController_setControllerType($IStorCtrHD, $os{recommendedHDStorageController});
            IStorageController_setPortCount($IStorCtrHD, IStorageController_getMinPortCount($IStorCtrHD)); # Controllers have all ports on by default. Set to the minimum
        }

        foreach my $slot (0..7) {
            my $INetworkAdapter = IMachine_getNetworkAdapter($IMachine, $slot);
            INetworkAdapter_setAdapterType($INetworkAdapter, $os{adapterType});
        }

        IVRDEServer_setVRDEProperty($IVRDEServer, 'VideoChannel/Quality', 75);
        if ($$vhost{vrdeextpack} =~ m/vnc/i) { IVRDEServer_setVRDEProperty($IVRDEServer, 'TCP/Ports', $prefs{DEFVNCPORTS}) }
        else { IVRDEServer_setVRDEProperty($IVRDEServer, 'TCP/Ports', $prefs{DEFRDPPORTS}); }
        IVRDEServer_setEnabled($IVRDEServer, 'true');
        IVRDEServer_setAllowMultiConnection($IVRDEServer, 'true');
        IMachine_saveSettings($IMachine);
        IVirtualBox_registerMachine($gui{websn}, $IMachine);
        &addrow_log("Created a new guest: $$newref{name}.");
    }

    return $IMachine, $dvdctrname, $hdctrname, $floppyctrname;
}

# Creates a new hard disk and shows a progress window
sub create_new_hd {
    my ($newref) = @_;
    my $ext = 'hdd';
    # All formats use an extension the same as their name except parallels
    $ext = $$newref{imgformat} unless ($$newref{imgformat} eq 'parallels');
    my $IMedium = IVirtualBox_createMedium($gui{websn}, $$newref{imgformat}, &rcatfile($$newref{location}, "$$newref{diskname}.$ext"), 'ReadWrite', 'HardDisk');
    my $IProgress = IMedium_createBaseStorage($IMedium, $$newref{size}, $$newref{allocation});
    &show_progress_window($IProgress, 'Creating Hard Disk', $gui{img}{ProgressMediaCreate});

    if (IProgress_getCanceled($IProgress) eq 'true') {
        &addrow_log("Cancelled hard disk creation");
        IManagedObjectRef_release($IMedium);
        $IMedium = undef;
    }
    else { &addrow_log("Created new hard disk: " . &rcatfile($$newref{location}, "$$newref{diskname}.$ext")); }

    Gtk2->main_iteration() while Gtk2->events_pending();
    return $IMedium;
}

sub newgen_osfam {
    my ($combofam, $combover) = @_;
    my ($osfam, $osver) = &osfamver();
    my $fam = &getsel_combo($combofam, 1);
    $combofam->signal_handler_block($signal{fam}); # Block to avoid signal emission when changing
    $combover->signal_handler_block($signal{ver});
    $gui{liststoreNewOSVer}->clear();

    foreach my $ver (@{ $$osfam{$fam}{verids} })
    {
        my $iter = $gui{liststoreNewOSVer}->append();
        $gui{liststoreNewOSVer}->set($iter, 0, $$osver{$ver}{description}, 1, $ver, 2, $$osver{$ver}{icon});
        $combover->set_active_iter($iter) if ($ver eq 'Windows10_64' | $ver eq 'Fedora_64' | $ver eq 'Solaris11_64' | $ver eq 'FreeBSD_64' | $ver eq 'DOS');
    }

    $combover->set_active(0) if ($combover->get_active() == -1);
    $combofam->signal_handler_unblock($signal{fam});
    $combover->signal_handler_unblock($signal{ver});
    $combover->signal_emit('changed'); # Force update of other fields based on OS
}

sub newgen_osver {
    my ($combover, $combofam) = @_;
    my $osver = &osver();
    my $ver = &getsel_combo($combover, 1);
    $combofam->signal_handler_block($signal{fam}); # Avoid signal emission when changing
    $combover->signal_handler_block($signal{ver});
    $gui{spinbuttonNewMemory}->set_value($$osver{$ver}{recommendedRAM});
    $gui{spinbuttonNewNewHDSize}->set_value($$osver{$ver}{recommendedHDD} / 1048576);
    $combofam->signal_handler_unblock($signal{fam});
    $combover->signal_handler_unblock($signal{ver});
}

sub newstor_new_exist {
    my ($widget) = @_;
    my $buttongrp = $widget->get_group();

    if ($$buttongrp[0]->get_active() == 1) {
        $gui{comboboxNewChooseHD}->set_sensitive(1); # This is use an existing HD
        $gui{tableNewNewHD}->set_sensitive(0);
    }
    else {
        $gui{comboboxNewChooseHD}->set_sensitive(0); # This is creating a new HD
        $gui{tableNewNewHD}->set_sensitive(1);
    }
}

# Handle the toggle startup disk selection
sub toggle_newstartupdisk {
    if ($gui{checkbuttonNewNewHD}->get_active() == 1) {
        $gui{radiobuttonNewNewHD}->show();
        $gui{radiobuttonNewExistingHD}->show();
        $gui{tableNewNewHD}->show();
        $gui{comboboxNewChooseHD}->show();
    }
    else {
        $gui{radiobuttonNewNewHD}->hide();
        $gui{radiobuttonNewExistingHD}->hide();
        $gui{tableNewNewHD}->hide();
        $gui{comboboxNewChooseHD}->hide();
    }
}

# Handle the generate new MACs depending on clone type
sub clone_type {
    if ($gui{comboboxCloneType}->get_active() == 2) { $gui{checkbuttonCloneNewMACs}->hide(); }
    else { $gui{checkbuttonCloneNewMACs}->show(); }
}

# Handle the radio button sensitivity when selecting an image format when
# creating a new hd for a new guest
sub sens_hdformatchanged {
    my $format = &getsel_combo($gui{comboboxNewNewFormat}, 1);
    $gui{radiobuttonNewDynamic}->set_active(1);

    if ($format eq 'vmdk') {
        $gui{radiobuttonNewDynamic}->set_sensitive(1);
        $gui{radiobuttonNewFixed}->set_sensitive(1);
        $gui{radiobuttonNewSplit}->set_sensitive(1);
    }
    elsif ($format eq 'vdi' or $format eq 'vhd') {
        $gui{radiobuttonNewDynamic}->set_sensitive(1);
        $gui{radiobuttonNewFixed}->set_sensitive(1);
        $gui{radiobuttonNewSplit}->set_sensitive(0);
    }
    else {
        $gui{radiobuttonNewDynamic}->set_sensitive(1);
        $gui{radiobuttonNewFixed}->set_sensitive(0);
        $gui{radiobuttonNewSplit}->set_sensitive(0);
    }
}

1;
