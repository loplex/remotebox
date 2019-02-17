# Edit System Settings of a Guest
use strict;
use warnings;
our (%gui, %vmc);

# Sets up the initial state of the system tab of the edit settings dialog
sub setup_edit_dialog_system {
    my $vhost = &vhost();
    &addrow_log("Fetching system settings for $vmc{Name}...");
    &busy_pointer($gui{dialogEdit}, 0);
    $gui{buttonEditSysBootUp}->set_sensitive(0);
    $gui{buttonEditSysBootDown}->set_sensitive(0);
    $gui{liststoreEditSysBoot}->clear();

    if (IMachine_getFirmwareType($vmc{IMachine}) =~ m/^EFI/) { $gui{checkbuttonEditSysEFI}->set_active(1); }
    else { $gui{checkbuttonEditSysEFI}->set_active(0); }

    $gui{entryEditSysLogoPath}->set_text(IBIOSSettings_getLogoImagePath($vmc{IBIOSSettings}));
    $gui{spinbuttonEditSysMem}->set_range(4, $$vhost{memsize});
    $gui{spinbuttonEditSysMem}->set_value(IMachine_getMemorySize($vmc{IMachine}));
    $gui{spinbuttonEditSysTimeOffset}->set_value(IBIOSSettings_getTimeOffset($vmc{IBIOSSettings}));
    $gui{spinbuttonEditSysLogoTime}->set_value(IBIOSSettings_getLogoDisplayTime($vmc{IBIOSSettings}));
    $gui{hscaleEditSysProcessor}->set_range($$vhost{minguestcpu}, $$vhost{maxhostcpuon} + 1); # +1 works around GTK bug
    $gui{hscaleEditSysProcessor}->set_value(IMachine_getCPUCount($vmc{IMachine}));
    $gui{hscaleEditSysProcessorCap}->set_value(IMachine_getCPUExecutionCap($vmc{IMachine}));
    $gui{checkbuttonEditSysVTX}->set_active(&bl(IMachine_getHWVirtExProperty($vmc{IMachine}, 'Enabled')));
    $gui{checkbuttonEditSysNested}->set_active(&bl(IMachine_getHWVirtExProperty($vmc{IMachine}, 'NestedPaging')));
    $gui{checkbuttonEditSysVPID}->set_active(&bl(IMachine_getHWVirtExProperty($vmc{IMachine}, 'VPID')));
    $gui{checkbuttonEditSysLargePages}->set_active(&bl(IMachine_getHWVirtExProperty($vmc{IMachine}, 'LargePages')));
    $gui{checkbuttonEditSysAPIC}->set_active(&bl(IBIOSSettings_getIOAPICEnabled($vmc{IBIOSSettings})));
    $gui{checkbuttonEditSysPAE}->set_active(&bl(IMachine_getCPUProperty($vmc{IMachine}, 'PAE')));
    $gui{checkbuttonEditSysCPUHotPlug}->set_active(&bl(IMachine_getCPUHotPlugEnabled($vmc{IMachine})));
    $gui{checkbuttonEditSysHPET}->set_active(&bl(IMachine_getHPETEnabled($vmc{IMachine})));
    $gui{checkbuttonEditSysFusion}->set_active(&bl(IMachine_getPageFusionEnabled($vmc{IMachine})));
    $gui{checkbuttonEditSysUTC}->set_active(&bl(IMachine_getRTCUseUTC($vmc{IMachine})));
    $gui{checkbuttonEditSysFadeIn}->set_active(&bl(IBIOSSettings_getLogoFadeIn($vmc{IBIOSSettings})));
    $gui{checkbuttonEditSysFadeOut}->set_active(&bl(IBIOSSettings_getLogoFadeOut($vmc{IBIOSSettings})));
    &combobox_set_active_text($gui{comboboxEditSysParavirt}, IMachine_getParavirtProvider($vmc{IMachine}));
    &combobox_set_active_text($gui{comboboxEditSysChipset}, IMachine_getChipsetType($vmc{IMachine}));
    &combobox_set_active_text($gui{comboboxEditSysPointing}, IMachine_getPointingHIDType($vmc{IMachine}));
    &combobox_set_active_text($gui{comboboxEditSysKeyboard}, IMachine_getKeyboardHIDType($vmc{IMachine}));

    # Default to maxbootpos+1 to mean 'not set in boot order' but this number needs to be higher than
    # true boot order numbers so the disabled devices appear at the end of the list.
    my %bootorder = (Floppy   => $$vhost{maxbootpos} + 1,
                     DVD      => $$vhost{maxbootpos} + 1,
                     HardDisk => $$vhost{maxbootpos} + 1,
                     Network  => $$vhost{maxbootpos} + 1);

    my %devdesc = (Floppy   => 'Floppy Disk',
                   DVD      => 'Optical Disc',
                   HardDisk => 'Hard Disk',
                   Network  => 'Network');

    # Find boot order and set value in hash accordingly. Empty boot slots return 'Null' so skip them
    foreach (1..$$vhost{maxbootpos}) {
        my $bootdev = IMachine_getBootOrder($vmc{IMachine}, $_);
        next if ($bootdev eq 'Null');
        $bootorder{$bootdev} = $_;
    }
    # Returns hash keys sorted by value (ie boot order). Disabled devices appear at end
    foreach my $dev (sort {$bootorder{$a} cmp $bootorder{$b}} keys %bootorder) {
        if ($bootorder{$dev} == $$vhost{maxbootpos} + 1) {
            my $iter = $gui{liststoreEditSysBoot}->append();
            $gui{liststoreEditSysBoot}->set($iter, 0, 0, 1, $dev, 2, $gui{img}{$dev}, 3, $devdesc{$dev});
        }
        else {
            my $iter = $gui{liststoreEditSysBoot}->append();
            $gui{liststoreEditSysBoot}->set($iter, 0, 1, 1, $dev, 2, $gui{img}{$dev}, 3, $devdesc{$dev});
        }
    }

    &busy_pointer($gui{dialogEdit}, 0);
    &addrow_log('System settings complete.');
}

# Sets the amount of main system memory
sub sys_mem {
    if ($vmc{SessionType} eq 'WriteLock') {
        IMachine_setMemorySize($vmc{IMachine}, $gui{spinbuttonEditSysMem}->get_value_as_int());
        return 0;
    }
}

# Sets with IO APIC should be enabled or not in the guest
sub sys_ioapic { if ($vmc{SessionType} eq 'WriteLock') { IBIOSSettings_setIOAPICEnabled($vmc{IBIOSSettings}, $gui{checkbuttonEditSysAPIC}->get_active()); } }

# Sets whether the machine should use EFI or the traditional BIOS
sub sys_efi {
    if ($vmc{SessionType} eq 'WriteLock') {
        if ($gui{checkbuttonEditSysEFI}->get_active() == 1) { IMachine_setFirmwareType($vmc{IMachine}, 'EFI'); }
        else { IMachine_setFirmwareType($vmc{IMachine}, 'BIOS'); }
    }
}

# Set the number of processors. The exact mechanism varies depending on hot plug mode
sub sys_processors {
    if ($vmc{SessionType} eq 'WriteLock') {
        my $newcpucount = int($gui{adjustmentEditSysProcessor}->get_value());

        # In hot-plug mode, if we reduce the number of CPUs, we must offline them first.
        if (&bl(IMachine_getCPUHotPlugEnabled($vmc{IMachine}))) {
            my $curcpucount = IMachine_getCPUCount($vmc{IMachine});

            if ($newcpucount < $curcpucount) {
                foreach my $num ($newcpucount..($curcpucount-1)) {
                    IMachine_hotUnplugCPU($vmc{IMachine}, $num) if (&bl(IMachine_getCPUStatus($vmc{IMachine}, $num)));
                }
            }
        }

        IMachine_setCPUCount($vmc{IMachine}, $newcpucount);
        return 0;
    }
}

# Formats the slider value for the processors
sub sys_processors_fmt {
    my ($widget, $value) = @_;
    return " $value vCPUs";
}

# Sets the processor execution CAP
sub sys_processorcap {
    IMachine_setCPUExecutionCap($vmc{IMachine}, int($gui{adjustmentEditSysProcessorCap}->get_value()));
    return 0;
}

# Formats the slider for the execution cap
sub sys_processorcap_fmt {
    my ($widget, $value) = @_;
    return " $value% Max";
}

# Whether the guest uses Physical Address Extensions and No Execution
sub sys_pae { if ($vmc{SessionType} eq 'WriteLock') { IMachine_setCPUProperty($vmc{IMachine}, 'PAE', $gui{checkbuttonEditSysPAE}->get_active()); } }

# Whether the guest uses hardware accelerator (if available)
sub sys_vtx { if ($vmc{SessionType} eq 'WriteLock') { IMachine_setHWVirtExProperty($vmc{IMachine}, 'Enabled', $gui{checkbuttonEditSysVTX}->get_active()); } }

# Toggle the CPU Hot Plug Flag
sub sys_cpuhotplug {
    if ($vmc{SessionType} eq 'WriteLock') {
        # if true we are about to enable hotplug otherwise disable
        if ($gui{checkbuttonEditSysCPUHotPlug}->get_active()) {
            IMachine_setCPUHotPlugEnabled($vmc{IMachine}, 1);
        }
        else {
            # If disabling hot plug we must offline the CPUs first
            my $cpucount = IMachine_getCPUCount($vmc{IMachine});

            foreach my $num (1..($cpucount-1)) {
                IMachine_hotUnplugCPU($vmc{IMachine}, $num) if (&bl(IMachine_getCPUStatus($vmc{IMachine}, $num)));
            }
            IMachine_setCPUCount($vmc{IMachine}, 1);
            IMachine_setCPUHotPlugEnabled($vmc{IMachine}, 0);
            IMachine_setCPUCount($vmc{IMachine}, $cpucount);
        }
    }
}

# Sets whether the guest will be involved in 'memory dedupe'
sub sys_pagefusion { if ($vmc{SessionType} eq 'WriteLock') { IMachine_setPageFusionEnabled($vmc{IMachine}, $gui{checkbuttonEditSysFusion}->get_active()); } }

# Whether to use large pages instead of the normal page size
sub sys_largepages { if ($vmc{SessionType} eq 'WriteLock') { IMachine_setHWVirtExProperty($vmc{IMachine}, 'LargePages', $gui{checkbuttonEditSysLargePages}->get_active()); } }

# Sets whether the guest has a High Precision Event Timer
sub sys_hpet { if ($vmc{SessionType} eq 'WriteLock') { IMachine_setHPETEnabled($vmc{IMachine}, $gui{checkbuttonEditSysHPET}->get_active()); } }

# Whether to fade the BIOS boot logo in
sub sys_fadein { if ($vmc{SessionType} eq 'WriteLock') { IBIOSSettings_setLogoFadeIn($vmc{IBIOSSettings}, $gui{checkbuttonEditSysFadeIn}->get_active()); } }

# Whether to fade the BIOS boot logo out
sub sys_fadeout { if ($vmc{SessionType} eq 'WriteLock') { IBIOSSettings_setLogoFadeOut($vmc{IBIOSSettings}, $gui{checkbuttonEditSysFadeOut}->get_active()); } }

# The amount of time to display the BIOS boot logo
sub sys_logodisptime {
    if ($vmc{SessionType} eq 'WriteLock') {
        my $time = $gui{spinbuttonEditSysLogoTime}->get_value_as_int();
        $time = 65535 if ($time > 65535);
        $time = 0 if ($time < 0);
        IBIOSSettings_setLogoDisplayTime($vmc{IBIOSSettings}, $time);
        return 0; # Must return this value for the signal used.
    }
}

# Sets an alternative BIOS boot screen (BMP)
sub sys_bioslogopath {
    if ($vmc{SessionType} eq 'WriteLock') {
        IBIOSSettings_setLogoImagePath($vmc{IBIOSSettings}, $gui{entryEditSysLogoPath}->get_text());
        return 0;
    }
}

# Sets whether the guest clock runs at a time offset
sub sys_timeoffset {
    if ($vmc{SessionType} eq 'WriteLock') {
        IBIOSSettings_setTimeOffset($vmc{IBIOSSettings}, $gui{spinbuttonEditSysTimeOffset}->get_value_as_int());
        return 0; # Must return this value for the signal used.
    }
}

# Sets whether the guest clock is UTC or local time
sub sys_utc { if ($vmc{SessionType} eq 'WriteLock') { IMachine_setRTCUseUTC($vmc{IMachine}, $gui{checkbuttonEditSysUTC}->get_active()); } }

# Sets the emulated pointing (eg mouse) device
sub sys_pointer { if ($vmc{SessionType} eq 'WriteLock') { IMachine_setPointingHIDType($vmc{IMachine}, &getsel_combo($gui{comboboxEditSysPointing}, 0)); } }

# Sets the emulatyed keyboard type
sub sys_keyboard { if ($vmc{SessionType} eq 'WriteLock') { IMachine_setKeyboardHIDType($vmc{IMachine}, &getsel_combo($gui{comboboxEditSysKeyboard}, 0)); } }

# Sets the emulated motherboard chipset
sub sys_chipset { if ($vmc{SessionType} eq 'WriteLock') { IMachine_setChipsetType($vmc{IMachine}, &getsel_combo($gui{comboboxEditSysChipset}, 0)); } }

# Sets the paravirtualization interface
sub sys_paravirt { if ($vmc{SessionType} eq 'WriteLock') { IMachine_setParavirtProvider($vmc{IMachine}, &getsel_combo($gui{comboboxEditSysParavirt}, 0)); } }

# Whether the guest uses Nested Paging
sub sys_nestedpaging { if ($vmc{SessionType} eq 'WriteLock') { IMachine_setHWVirtExProperty($vmc{IMachine}, 'NestedPaging', $gui{checkbuttonEditSysNested}->get_active()); } }

# Whether the guest uses VPID
sub sys_vpid { if ($vmc{SessionType} eq 'WriteLock') { IMachine_setHWVirtExProperty($vmc{IMachine}, 'VPID', $gui{checkbuttonEditSysVPID}->get_active()); } }

# Moves the boot device to a higher priority
sub sys_boot_higher {
    if ($vmc{SessionType} eq 'WriteLock') {
        my ($model, $iter) = $gui{treeviewEditSysBoot}->get_selection->get_selected;
        my $path = $model->get_path($iter);
        $path->prev;
        my $previter = $model->get_iter($path);
        $model->move_before($iter, $previter);
    }
}

# Moves the boot device to a lower priority
sub sys_boot_lower {
    if ($vmc{SessionType} eq 'WriteLock') {
        my ($model, $iter) = $gui{treeviewEditSysBoot}->get_selection->get_selected;
        my $nextiter = $model->iter_next($iter);
        $model->move_after($iter, $nextiter) if ($nextiter);
    }
}

sub sys_bootorder {
    my $model = $gui{treeviewEditSysBoot}->get_model();
    my $iter = $model->get_iter_first();
    my $i = 1;

    while ($iter) {
        my $dev = $model->get($iter,1);
        $dev = 'Null' if ($model->get($iter,0) == 0);
        IMachine_setBootOrder($vmc{IMachine}, $i, $dev);
        $iter = $model->iter_next($iter);
        $i++;
    }
}

# Sets the sensitivity when a boot item is selected
sub sens_boot_selected {
    $gui{buttonEditSysBootDown}->set_sensitive(1);
    $gui{buttonEditSysBootUp}->set_sensitive(1);
}

sub sys_boot_toggle {
    my ($widget, $path_str, $model) = @_;
    my $iter = $model->get_iter(Gtk2::TreePath->new_from_string($path_str));
    my $val = $model->get($iter, 0);
    $model->set ($iter, 0, !$val); # Always set the opposite of val to act as a toggle
}

1;
