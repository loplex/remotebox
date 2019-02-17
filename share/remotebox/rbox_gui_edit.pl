# Editing Settings of a Guest
use strict;
use warnings;
require 'rbox_gui_edit_general.pl';
require 'rbox_gui_edit_system.pl';
require 'rbox_gui_edit_display.pl';
require 'rbox_gui_edit_storage.pl';
require 'rbox_gui_edit_audio.pl';
require 'rbox_gui_edit_network.pl';
require 'rbox_gui_edit_ioports.pl';
require 'rbox_gui_edit_usb.pl';
require 'rbox_gui_edit_shared.pl';
our (%gui, %vmc);

sub show_dialog_edit {
    undef(%vmc);
    my $gref = &getsel_list_guest();
    return if (!$$gref{IMachine}); # Do nothing if it was a group double clicked
    &busy_window($gui{windowMain}, 0, 'watch');
    my $sref = &get_session($$gref{IMachine});

    if ($$sref{Lock} eq 'VM' or $$sref{Lock} eq 'Shared') {
        &addrow_log("Fetching master settings for $$gref{Name}...");
        $vmc{IMachine} = $$sref{IMachine};
        $vmc{USBFilters} = IMachine_getUSBDeviceFilters($vmc{IMachine});
        $vmc{IBIOSSettings} = IMachine_getBIOSSettings($vmc{IMachine});
        $vmc{IAudioAdapter} = IMachine_getAudioAdapter($vmc{IMachine});
        $vmc{IVRDEServer} = IMachine_getVRDEServer($vmc{IMachine});
        $vmc{IParallelPort} = IMachine_getParallelPort($vmc{IMachine}, 0);
        $vmc{IHost} = IVirtualBox_getHost($gui{websn});
        $vmc{Name} = $$gref{Name};
        $vmc{SessionType} = $$sref{Type};
        edit_tabchanged($gui{notebookEdit}, 0, $gui{notebookEdit}->get_current_page()); # Setup initial tab
        &addrow_log('Master settings complete.');
        &busy_window($gui{windowMain}, 0);

        # Here we need to change some widgets depending on the lock type
        # because some settings cannot be changed while the guest is locked
        my $storagepage = $gui{notebookEdit}->get_nth_page(3);
        my $iopage = $gui{notebookEdit}->get_nth_page(6);
        my $audiopage = $gui{notebookEdit}->get_nth_page(4);
        my $genbasicpage = $gui{notebookEditGen}->get_nth_page(0);
        my $sysmotherboard = $gui{notebookEditSys}->get_nth_page(0);
        my $sysadvanced = $gui{notebookEditSys}->get_nth_page(2);
        my $sysaccel = $gui{notebookEditSys}->get_nth_page(3);
        my $sysbootpage = $gui{notebookEditSys}->get_nth_page(4);
        my $dispvideopage = $gui{notebookEditDisp}->get_nth_page(0);
        my $encryptionpage = $gui{notebookEditGen}->get_nth_page(3);

        if ($vmc{SessionType} eq 'WriteLock') {
            $gui{dialogEdit}->set_title("Edit Settings - $$gref{Name}");
            $storagepage->set_sensitive(1);
            $iopage->set_sensitive(1);
            $genbasicpage->set_sensitive(1);
            # This can only be changed if there are no snapshots
            my $snapcount = IMachine_getSnapshotCount($vmc{IMachine});
            if ($snapcount) {
                $gui{entryEditGenSnapFolder}->set_sensitive(0);
                $gui{entryEditGenSnapFolder}->set_sensitive(0);
            }
            else {
                $gui{entryEditGenSnapFolder}->set_sensitive(1);
                $gui{buttonEditGenSnapFolder}->set_sensitive(1);
            }
            $sysmotherboard->set_sensitive(1);
            $sysadvanced->set_sensitive(1);
            $sysaccel->set_sensitive(1);
            $sysbootpage->set_sensitive(1);
            $encryptionpage->set_sensitive(1);
            $gui{hscaleEditSysProcessor}->set_sensitive(1);
            $gui{checkbuttonEditSysPAE}->set_sensitive(1);
            $gui{checkbuttonEditSysCPUHotPlug}->set_sensitive(1);
            $dispvideopage->set_sensitive(1);
            $gui{checkbuttonEditDispMultiple}->set_sensitive(1);
            $audiopage->set_sensitive(1);
            $gui{checkbuttonEditNetEnable}->set_sensitive(1);
            $gui{entryEditNetMac}->set_sensitive(1);
            $gui{buttonEditNetGenerateMac}->set_sensitive(1);
            $gui{comboboxEditNetType}->set_sensitive(1);
            $gui{radiobuttonEditUSB1}->set_sensitive(1);
            $gui{radiobuttonEditUSB2}->set_sensitive(1);
            $gui{radiobuttonEditUSB3}->set_sensitive(1);
            $gui{checkbuttonEditUSBEnable}->set_sensitive(1);
            $gui{labelEditOnline}->hide();
            $gui{buttonEditCancel}->show();
        }
        else {
            $gui{dialogEdit}->set_title("Online Edit Settings - $$gref{Name}");
            $storagepage->set_sensitive(0);
            $iopage->set_sensitive(0);
            $genbasicpage->set_sensitive(0);
            $gui{entryEditGenSnapFolder}->set_sensitive(0);
            $gui{buttonEditGenSnapFolder}->set_sensitive(0);
            $sysmotherboard->set_sensitive(0);
            $sysadvanced->set_sensitive(0);
            $sysaccel->set_sensitive(0);
            $sysbootpage->set_sensitive(0);
            $encryptionpage->set_sensitive(0);
            $gui{hscaleEditSysProcessor}->set_sensitive(0);
            $gui{checkbuttonEditSysPAE}->set_sensitive(0);
            $gui{checkbuttonEditSysCPUHotPlug}->set_sensitive(0);
            $dispvideopage->set_sensitive(0);
            $gui{checkbuttonEditDispMultiple}->set_sensitive(0);
            $audiopage->set_sensitive(0);
            $gui{checkbuttonEditNetEnable}->set_sensitive(0);
            $gui{entryEditNetMac}->set_sensitive(0);
            $gui{buttonEditNetGenerateMac}->set_sensitive(0);
            $gui{comboboxEditNetType}->set_sensitive(0);
            $gui{tableEditDispCapture}->set_sensitive(0);
            $gui{checkbuttonEditUSBEnable}->set_sensitive(0);
            $gui{radiobuttonEditUSB1}->set_sensitive(0);
            $gui{radiobuttonEditUSB2}->set_sensitive(0);
            $gui{radiobuttonEditUSB3}->set_sensitive(0);
            $gui{labelEditOnline}->show();
            $gui{buttonEditCancel}->hide();
        }

        # Extradata doesn't get discarded on a cancel so we backup here and manually restore.
        my $floppya = IMachine_getExtraData($vmc{IMachine}, 'VBoxInternal/Devices/i82078/0/LUN#0/Config/Type');
        my $floppyb = IMachine_getExtraData($vmc{IMachine}, 'VBoxInternal/Devices/i82078/0/LUN#1/Config/Type');

        my $response = $gui{dialogEdit}->run;
        $gui{dialogEdit}->hide;

        if ($response eq 'ok') {
            # We will apply encryption settings here as it's not possible to
            # do it in real time
            if ($gui{checkbuttonEditGenEncryption}->get_state()) {
                my $cipher = &getsel_combo($gui{comboboxEditGenEncryptionCipher}, 0);
                if ($cipher ne 'Unchanged') {

                    my $passwd1 = $gui{entryEditGenEncryptionPass}->get_text();
                    my $passwd2 = $gui{entryEditGenEncryptionPassCon}->get_text();

                    if ($passwd1) {
                        if ($passwd1 ne $passwd2) { &show_err_msg('encdiskpasswd'); }
                        else {
                            my @IMediumAttachment = IMachine_getMediumAttachments($vmc{IMachine});
                            my %used_key_ids; # So we only ask for a Key ID once

                            foreach my $attach (@IMediumAttachment) {
                                next if ($$attach{type} ne 'HardDisk');

                                if (&imedium_has_property($$attach{medium}, 'CRYPT/KeyStore')) {
                                    # Disk is already encryped, so see if we can re-encrypt it
                                    my $keyid = IMedium_getProperty($$attach{medium}, 'CRYPT/KeyId');

                                    if (!$used_key_ids{$keyid}) {
                                        my $npasswd = &show_dialog_decpasswd($$attach{medium}, $keyid);
                                        &encrypt_disk($$attach{medium}, $npasswd, $cipher, $passwd1, $vmc{Name}) if ($npasswd);
                                        $used_key_ids{$keyid} = $npasswd;
                                    }
                                }
                                else {
                                    &encrypt_disk($$attach{medium}, '', $cipher, $passwd1, $vmc{Name});
                                }
                            }
                        }
                    }
                }
            }
            IMachine_saveSettings($vmc{IMachine});
            &fill_list_guest();
            &addrow_log("Saved all settings for $$gref{Name}.");
        }
        else {
            IMachine_discardSettings($vmc{IMachine});
            # Restore the floppy drive types as discardSettings does not do this. But only IF there's a setting as the floppy drive may have been deleted already and explicitly saved
            IMachine_setExtraData($vmc{IMachine}, 'VBoxInternal/Devices/i82078/0/LUN#0/Config/Type', $floppya) if (IMachine_getExtraData($vmc{IMachine}, 'VBoxInternal/Devices/i82078/0/LUN#0/Config/Type'));
            IMachine_setExtraData($vmc{IMachine}, 'VBoxInternal/Devices/i82078/0/LUN#1/Config/Type', $floppyb) if (IMachine_getExtraData($vmc{IMachine}, 'VBoxInternal/Devices/i82078/0/LUN#1/Config/Type'));
            &addrow_log("Discarded changed settings for $$gref{Name}.");
        }

        undef(%vmc);
        &edit_tabchanged(); # Flush the page cache
        $gui{menuitemAttachFloppy} = $gui{menuitemAttachDVD} = $gui{menuitemAttachHD} = $gui{menuAttachFloppy} =
        $gui{menuAttachDVD} = $gui{menuAttachHD} = $gui{menuAttachAdd} = $gui{menuUSB} = undef; # These must be freed
    }
    else { &show_err_msg('settings'); }

    ISession_unlockMachine($$sref{ISession}) if (ISession_getState($$sref{ISession}) eq 'Locked');
}

# Routine only retrieves the settings for a tab when the user clicks on it.
# Helps reduce time it takes to open window. Results are cached until window closed
{
    my %pagecache;

    sub edit_tabchanged {
        my ($widget, $focus, $page) = @_;
        # Flush the cache if we have not been called by a widget
        if (!$widget) { undef %pagecache; }
        else {
            if ($pagecache{$page}) { } # Do Nothing, Page is Cached
            elsif ($page == 0) { &setup_edit_dialog_general(); }
            elsif ($page == 1) { &setup_edit_dialog_system(); }
            elsif ($page == 2) { &setup_edit_dialog_display(); }
            elsif ($page == 3) { &setup_edit_dialog_storage(); }
            elsif ($page == 4) { &setup_edit_dialog_audio(); }
            elsif ($page == 5) { &setup_edit_dialog_network(); }
            elsif ($page == 6) { &setup_edit_dialog_ioports(); }
            elsif ($page == 7) { &setup_edit_dialog_usb(); }
            elsif ($page == 8) { &setup_edit_dialog_shared(); }
            $pagecache{$page} = 1;
        }
    }
};

1;
