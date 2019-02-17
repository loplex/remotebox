# Edit General Settings of a Guest
use strict;
use warnings;
our (%gui, %signal, %vmc);

sub setup_edit_dialog_general {
    my ($osfam, $osver) = &osfamver();
    &addrow_log("Fetching general settings for $vmc{Name}...");
    &busy_pointer($gui{dialogEdit}, 1);
    my $Name = IMachine_getName($vmc{IMachine});
    my $Osid = IMachine_getOSTypeId($vmc{IMachine});
    $gui{comboboxEditGenOSFam}->signal_handler_block($signal{famedit});
    $gui{comboboxEditGenOSVer}->signal_handler_block($signal{veredit});
    $gui{liststoreEditGenOSFam}->clear();
    $gui{liststoreEditGenOSVer}->clear();
    my $IGuestOSType = IVirtualBox_getGuestOSType($gui{websn}, $Osid);
    $gui{entryEditGenName}->set_text($Name);

    foreach (sort {
                    if    ($$osfam{$a}{description} =~ m/Other/) { return 1; }
                    elsif ($$osfam{$b}{description} =~ m/Other/) { return -1; }
                    else  { return lc($$osfam{$a}{description}) cmp lc($$osfam{$b}{description}) }
                  } keys %{$osfam}) {
        my $iter = $gui{liststoreEditGenOSFam}->append();
        $gui{liststoreEditGenOSFam}->set($iter, 0, $$osfam{$_}{description}, 1, $_, 2, $$osfam{$_}{icon});
        $gui{comboboxEditGenOSFam}->set_active_iter($iter) if ($_ eq $$IGuestOSType{familyId});
    }

    foreach (@{$$osfam{$$IGuestOSType{familyId}}{verids}})
    {
        my $iter = $gui{liststoreEditGenOSVer}->append();
        $gui{liststoreEditGenOSVer}->set($iter, 0, $$osver{$_}{description}, 1, $_, 2, $$osver{$_}{icon});
        $gui{comboboxEditGenOSVer}->set_active_iter($iter) if ($_ eq $$IGuestOSType{id});
    }

    &combobox_set_active_text($gui{comboboxEditGenClip}, IMachine_getClipboardMode($vmc{IMachine}));

    $gui{comboboxEditGenOSFam}->signal_handler_unblock($signal{famedit});
    $gui{comboboxEditGenOSVer}->signal_handler_unblock($signal{veredit});
    $gui{textbufferEditGenDescription}->set_text(IMachine_getDescription($vmc{IMachine}));

    my $vhost = &vhost();
    if ($$vhost{autostartdb}) {
        $gui{comboboxEditGenAutostop}->set_sensitive(1);
        $gui{checkbuttonEditGenAutostart}->set_sensitive(1);
        $gui{spinbuttonEditGenAutostartDelay}->set_sensitive(1);
        $gui{labelEditGenAutostartDelay}->set_sensitive(1);
        $gui{labelEditGenAutostop}->set_sensitive(1);
        &combobox_set_active_text($gui{comboboxEditGenAutostop}, IMachine_getAutostopType($vmc{IMachine}));
        $gui{checkbuttonEditGenAutostart}->set_active(&bl(IMachine_getAutostartEnabled($vmc{IMachine})));
        $gui{spinbuttonEditGenAutostartDelay}->set_value(IMachine_getAutostartDelay($vmc{IMachine}));
    }
    else {
        $gui{comboboxEditGenAutostop}->set_sensitive(0);
        $gui{checkbuttonEditGenAutostart}->set_sensitive(0);
        $gui{spinbuttonEditGenAutostartDelay}->set_sensitive(0);
        $gui{labelEditGenAutostartDelay}->set_sensitive(0);
        $gui{labelEditGenAutostop}->set_sensitive(0);
    }

    $gui{entryEditGenSnapFolder}->signal_handler_block($signal{snapfolderactivate});
    $gui{entryEditGenSnapFolder}->signal_handler_block($signal{snapfolderfocus});
    $gui{entryEditGenSnapFolder}->set_text(IMachine_getSnapshotFolder($vmc{IMachine}));
    $gui{entryEditGenSnapFolder}->signal_handler_unblock($signal{snapfolderactivate});
    $gui{entryEditGenSnapFolder}->signal_handler_block($signal{snapfolderfocus});


    # Determine if we have anything encrypted
    my @IMediumAttachment = IMachine_getMediumAttachments($vmc{IMachine});
    my $encrypted = 0;

    foreach my $attach (@IMediumAttachment) {
        next if (!$$attach{medium}); # Removable media may not have an attachment
        next if ($$attach{type} ne 'HardDisk');
        if (&imedium_has_property($$attach{medium}, 'CRYPT/KeyStore')) {
            $encrypted = 1;
            last; # We only care if at least 1 medium is encrypted
        }
    }

    $gui{checkbuttonEditGenEncryption}->set_active($encrypted);
    $gui{entryEditGenEncryptionPass}->set_text('');
    $gui{entryEditGenEncryptionPassCon}->set_text('');

    &busy_pointer($gui{dialogEdit}, 0);
    &addrow_log('General settings complete.');
}

# Sets the name of the guest
sub gen_name {
    if ($vmc{SessionType} eq 'WriteLock') {
        my $name = $gui{entryEditGenName}->get_text();
        IMachine_setName($vmc{IMachine}, $name) if ($name);
        return 0;
    }
}

# Sets the name of the snapshot folder
sub gen_snapfolder {
    if ($vmc{SessionType} eq 'WriteLock') {
        IMachine_setSnapshotFolder($vmc{IMachine}, $gui{entryEditGenSnapFolder}->get_text());
        return 0;
    }
}

sub gen_osfam {
    my ($combofam, $combover) = @_;
    my ($osfam, $osver) = &osfamver();
    my $fam = &getsel_combo($combofam, 1);
    $combofam->signal_handler_block($signal{famedit}); # Block to avoid signal emission when changing
    $combover->signal_handler_block($signal{veredit});
    $gui{liststoreEditGenOSVer}->clear();

    foreach (sort {
                    if    ($$osver{$a}{description} =~ m/Other/) { return 1; }
                    elsif ($$osver{$b}{description} =~ m/Other/) { return -1; }
                    else  { return lc($$osver{$a}{description}) cmp lc($$osver{$b}{description}) }

                  } @{ $$osfam{$fam}{verids} }) {
        my $iter = $gui{liststoreEditGenOSVer}->append();
        $gui{liststoreEditGenOSVer}->set($iter, 0, $$osver{$_}{description}, 1, $_, 2, $$osver{$_}{icon});
        $combover->set_active_iter($iter) if ($_ eq 'Windows10_64' | $_ eq 'Fedora_64' | $_ eq 'Solaris11_64'| $_ eq 'FreeBSD_64' | $_ eq 'DOS');
    }

    $combover->set_active(0) if ($combover->get_active() == -1);
    $combofam->signal_handler_unblock($signal{famedit});
    $combover->signal_handler_unblock($signal{veredit});
    $combover->signal_emit('changed'); # Force update of other fields based on OS
}

sub gen_osver {
    my ($combover) = @_;
    my $ver = &getsel_combo($combover, 1);
    IMachine_setOSTypeId($vmc{IMachine}, $ver);
}

sub gen_clip {
    IMachine_setClipboardMode($vmc{IMachine}, &getsel_combo($gui{comboboxEditGenClip}, 0));
    return 0;
}

# Set the guest to autostart on host boot
sub gen_autostart { IMachine_setAutostartEnabled($vmc{IMachine}, $gui{checkbuttonEditGenAutostart}->get_active()); }

# Set the guest's autostop type
sub gen_autostop {
    IMachine_setAutostopType($vmc{IMachine}, &getsel_combo($gui{comboboxEditGenAutostop}, 0));
    return 0;
}

# Set the autostart delay in seconds
sub gen_autostartdelay {
    IMachine_setAutostartDelay($vmc{IMachine}, $gui{spinbuttonEditGenAutostartDelay}->get_value_as_int());
    return 0; # Must return this value for the signal used.
}

# Sets the guest's description
sub gen_description {
    my $iter_s = $gui{textbufferEditGenDescription}->get_start_iter();
    my $iter_e = $gui{textbufferEditGenDescription}->get_end_iter();
    IMachine_setDescription($vmc{IMachine}, $gui{textbufferEditGenDescription}->get_text($iter_s, $iter_e, 0));
    return 0;
}

# Toggles GUI based on encrypted disks being attached
sub gen_encryption {
        my $state = $gui{checkbuttonEditGenEncryption}->get_active();
        $gui{tableEditGenEncryption}->set_sensitive($state);
}


1;
