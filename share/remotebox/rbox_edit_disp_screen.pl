# The Screen page of the Display Settings
use strict;
use warnings;
our (%gui, %vmc);

# Initialise the display page
sub init_edit_disp_screen() {
    &busy_pointer($gui{dialogEdit}, 1);
    my $vhost = &vhost();

    if (IMachine_getGraphicsControllerType($vmc{IMachine}) eq 'Null') { $gui{comboboxEditDispVGA}->set_active(0); }
    elsif (IMachine_getGraphicsControllerType($vmc{IMachine}) eq 'VBoxVGA') { $gui{comboboxEditDispVGA}->set_active(1); }
    elsif (IMachine_getGraphicsControllerType($vmc{IMachine}) eq 'VMSVGA') { $gui{comboboxEditDispVGA}->set_active(2); }
    else { $gui{comboboxEditDispVGA}->set_active(3); }

    $gui{spinbuttonEditDispVidMem}->set_range($$vhost{minguestvram}, $$vhost{maxguestvram});
    $gui{spinbuttonEditDispVidMem}->set_value(IMachine_getVRAMSize($vmc{IMachine}));
    $gui{spinbuttonEditDispMonitor}->set_range($$vhost{minmonitors}, $$vhost{maxmonitors});
    $gui{spinbuttonEditDispMonitor}->set_value(IMachine_getMonitorCount($vmc{IMachine}));
    $gui{checkbuttonEditDisp3D}->set_active(&bl(IMachine_getAccelerate3DEnabled($vmc{IMachine})));
    $gui{checkbuttonEditDisp2D}->set_active(&bl(IMachine_getAccelerate2DVideoEnabled($vmc{IMachine})));
    &busy_pointer($gui{dialogEdit}, 0);
}

# Set whether 2D acceleration is enabled
sub disp_scr_2D { IMachine_setAccelerate2DVideoEnabled($vmc{IMachine}, $gui{checkbuttonEditDisp2D}->get_active()); }

# Set whether 3D accelerator is enabled.
sub disp_scr_3D { IMachine_setAccelerate3DEnabled($vmc{IMachine}, $gui{checkbuttonEditDisp3D}->get_active()); }

# Set the virtual VGA card type
sub disp_scr_VGA { if ($vmc{SessionType} eq 'WriteLock') { IMachine_setGraphicsControllerType($vmc{IMachine}, &getsel_combo($gui{comboboxEditDispVGA}, 0)); } }

# Set the amount of video memory
sub disp_scr_vid_mem {
    if ($vmc{SessionType} eq 'WriteLock') {
        IMachine_setVRAMSize($vmc{IMachine}, int($gui{spinbuttonEditDispVidMem}->get_value_as_int()));
        return 0; # Must return this value for the signal used.
    }
}

# Set the number of virtual monitors
sub disp_scr_monitors {
    if ($vmc{SessionType} eq 'WriteLock') {
        IMachine_setMonitorCount($vmc{IMachine}, int($gui{spinbuttonEditDispMonitor}->get_value_as_int()));
        return 0; # Must return this value for the signal used.
    }
}

1;
