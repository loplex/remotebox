# Main Entry for RemoteBox
use strict;
use warnings;
our (%gui, %prefs, $docdir);
my %cmdopts=();

$endpoint = 'http://localhost:18083';
$fault = sub{}; # Do nothing with faults until connected
&rbprefs_get(); # Retrieve and set preferences
&restore_window_pos('windowMain');
&addrow_log("Welcome to $gui{appname} $gui{appver}");
getopts("H:u:p:h", \%cmdopts);

if($cmdopts{h}) {
    print STDERR <<USAGE;
Usage:
    $0 [-h]
    $0 [-H <host>] [-u <user>] [-p <pass>]

    -h        : Help
    -H <host> : Automatically connect to this virtualbox host
    -u <user> : Connect using this username. If omitted an empty username is assumed. Only useful with -H
    -p <pass> : Connect using this password. If omitted an empty password is assumed. Only useful with -H
USAGE
    exit 0;
}
elsif ($cmdopts{H}) { &show_dialog_connect('CMDAUTO'); } # Command line parameter based login
elsif ($prefs{AUTOCONNPROF}) { &show_dialog_connect('PROFAUTO'); } # Profile based automatic login

$0 = 'RemoteBox VirtualBox Client';
Gtk2->main;

sub quit_remotebox {
    &save_window_pos('windowMain'); # Also saves the main preferences
    &virtualbox_logoff();

    # These should be reset on exit to help garbage collection
    $gui{menuitemFloppy}->set_submenu(undef);
    $gui{menuitemDVD}->set_submenu(undef);
    $gui{menuitemUSB}->set_submenu(undef);
    $gui{menuitemFloppy}->set_submenu($gui{menutmp1});
    $gui{menuitemDVD}->set_submenu($gui{menutmp2});
    $gui{menuitemUSB}->set_submenu($gui{menutmp3});
    Gtk2->main_quit;
}

# Attempts to logon or fails with a dialog
sub virtualbox_logon {
    my ($url, $user, $password) = @_;
    &virtualbox_logoff(); # Ensure we disconnect from an existing connection
    $endpoint = $url;
    $fault = \&vboxlogonerror;
    $gui{websn} = IWebsessionManager_logon($user, $password);

    if ($gui{websn}) {
        $fault = \&vboxerror; # Install the fault capture
        $gui{heartbeat} = Glib::Timeout->add(58000, \&heartbeat) if ($prefs{HEARTBEAT}); # Install heartbeat if requested
        $gui{servermem} = Glib::Timeout->add(300000, \&update_server_membar);
        return 1;
    }
}

# Logoff and perform various necessary cleanups
sub virtualbox_logoff {
    my ($closewin) = @_;
    $fault = sub{}; # Disable fault capture. Protection against infinite loops
    Glib::Source->remove($gui{heartbeat}) if ($gui{heartbeat}); # Remove any heartbeat timers

    # Force close any open windows - usually because we've hit a fault. This will cause them to
    # execute their cancel operations
    if ($closewin) {
        foreach my $win (Gtk2::Window->list_toplevels()) {
            next if ($win eq $gui{windowMain});
            $win->hide;
        }
    }

    if ($gui{websn}) {
        IWebsessionManager_logoff($gui{websn});
        $gui{websn} = undef;
    }

    # Return GUI to a disconnected state
    &sens_unselected();
    &sens_connect(0);
    &clr_list_guest();
    &clr_vhost(); # Clear vhost so values are not retain on subsequent connections
}

# Fill in the fields when a profile is selected
sub select_profile {
    my ($widget) = @_;
    # For some reason this fires when deleting a profile from the profile manager.
    my $model = $widget->get_model();
    my $iter = $widget->get_active_iter();
    my @row = $model->get($iter) if ($iter and $model);

    if (@row) {
        $gui{entryConnectURL}->set_text($row[1]);
        $gui{entryConnectUser}->set_text($row[2]);
        $gui{entryConnectPassword}->set_text($row[3]);
    }
}

# Be careful with use of $vhost in this sub!
sub show_dialog_connect {
    my ($widget) = @_;
    my $response = 'cancel';

    $gui{checkbuttonConnectSSL}->set_active($prefs{SSLVERIFY});

    # Check if a command line automatic login has been requested. We do this here
    # to try an ensure that a cmdline login is as close as possible to a GUI login
    if ($widget eq 'CMDAUTO') {
        $gui{entryConnectURL}->set_text($cmdopts{H});
        $gui{entryConnectUser}->set_text($cmdopts{u}) if ($cmdopts{u});
        $gui{entryConnectPassword}->set_text($cmdopts{p}) if ($cmdopts{p});

        $response = 'ok';
        &addrow_log("Attempting a command line based automatic login to $cmdopts{H}");
    }
    elsif ($widget eq 'PROFAUTO') {
        my $model = $gui{treeviewConnectionProfiles}->get_model();
        my $iter = $model->get_iter_first();

        while($iter) {
            my @row = $model->get($iter);
            if ($row[0] eq $prefs{AUTOCONNPROF}) {
                $gui{entryConnectURL}->set_text($row[1]);
                $gui{entryConnectUser}->set_text($row[2]);
                $gui{entryConnectPassword}->set_text($row[3]);
                $response = 'ok';
                &addrow_log("Attempting a profile based automatic login to $row[1]");
                last;
            }
            $iter = $model->iter_next($iter);
        }
    }
    else {
        # Normal GUI login
        $gui{comboboxConnectProfile}->set_active(-1); # We don't want a current active
        $response = $gui{dialogConnect}->run;
        $gui{dialogConnect}->hide;
    }

    $gui{dialogConnect}->get_display->flush;

    if ($response eq 'ok') {
        my $url = $gui{entryConnectURL}->get_text();
        my $user = $gui{entryConnectUser}->get_text();
        $url = $endpoint if (!$url);
        $url =~ s/(\/)+$//g; # Remove all trailing
        $url = "http://$url" if ($url !~ m/^.+:\/\//);
        $url = "$url:18083" if ($url !~ m/:\d+$/);
        $prefs{URL}{$url} = 'URL' if ($url);
        $prefs{USER}{$user} = 'USER' if ($user);
        &rbprefs_save();

        # If we got a successful logon
        if (&virtualbox_logon($url, $user, $gui{entryConnectPassword}->get_text())) {
            my $ver = IVirtualBox_getVersion($gui{websn});

            if (!$ver) {
                &show_err_msg('connect', " ($url)");
                &virtualbox_logoff();
            }
            else {
                &addrow_log("Logged onto $endpoint");
                &addrow_log("Running VirtualBox $ver.");
                my $vhost = &vhost();
                &show_err_msg('vboxver', "Detected VirtualBox Version: $ver") if ($ver !~ m/^6.0/);

                if ($$vhost{vrdeextpack} =~ m/Oracle VM VirtualBox Extension Pack/i) { $gui{toolbuttonRemoteDisplay}->set_label('_Guest Display (RDP)'); }
                elsif ($$vhost{vrdeextpack} =~ m/vnc/i) {
                    $gui{toolbuttonRemoteDisplay}->set_label('_Guest Display (VNC)');
                    &addrow_log("WARNING: The Oracle VirtualBox Extension Pack is not installed.\nSome features may be unavailable.\nThis pack is only available for Linux, Windows, Solaris and MacOS X");
                }
                else {
                    $gui{toolbuttonRemoteDisplay}->set_label('Guest Display Unavailable');
                    &show_err_msg('noextensions');
                }

                if ($prefs{ADDADDITIONS}) {
                    &addrow_log('Adding Guest Additions ISO to VMM.');
                    my $additions = IVirtualBox_openMedium($gui{websn}, $$vhost{additionsiso}, 'DVD', 'ReadOnly', 'false') if ($$vhost{additionsiso});
                    if (!defined($additions)) { &addrow_log('WARNING: Could not automatically add guest additions ISO to VMM.'); }
                }

                &fill_list_guest();
                &sens_connect(1);
            }
        }
    }
}

# Shows the about dialog
sub show_dialog_about {
    $gui{aboutdialog}->run;
    $gui{aboutdialog}->hide;
}

# Shows the custom video hint dialog
sub show_dialog_videohint {
    $gui{spinbuttonCustomVideoW}->set_value($prefs{AUTOHINTDISPX});
    $gui{spinbuttonCustomVideoH}->set_value($prefs{AUTOHINTDISPY});
    $gui{dialogCustomVideo}->run;
    $gui{dialogCustomVideo}->hide;
    return [$gui{spinbuttonCustomVideoW}->get_value_as_int(), $gui{spinbuttonCustomVideoH}->get_value_as_int(), &getsel_combo($gui{comboboxCustomVideoD}, 1)];
}

# Shows a dialog with basic information about the VirtualBox server
sub show_dialog_serverinfo {
    &fill_list_serverinfo();
    $gui{dialogInfo}->set_title('Server Information');
    $gui{dialogInfo}->run;
    $gui{dialogInfo}->hide;
}

# Displays a dialog with the contents of the logs for a specific guest
sub show_dialog_log {
    my ($widget) = @_;
    my $gref = &getsel_list_guest();
    &fill_list_log($$gref{IMachine});
    $gui{dialogLog}->set_title("$$gref{Name} Guest Logs");
    $gui{dialogLog}->run;
    $gui{dialogLog}->hide;
}

# Saves a guest log to a text file. EOL encoding depends on server
sub log_save {
    my $gref = &getsel_list_guest();
    my $lognum = $gui{notebookLog}->get_current_page(); # We choose the log number by the page number
    $gui{filechooserLog}->set_current_name("$$gref{Name}_log$lognum" . '.txt');
    $gui{filechooserLog}->set_current_folder($ENV{HOME}) if ($ENV{HOME});
    my $response = $gui{filechooserLog}->run();
    $gui{filechooserLog}->hide();
    my $logfile = $gui{filechooserLog}->get_filename();

    if ($response eq 'ok' and $logfile) {
        &busy_pointer($gui{dialogLog}, 1);
        my $log;
        my $offset = 0;
        &addrow_log("Attempting to save guest log $logfile");

        if (IMachine_queryLogFilename($$gref{IMachine}, $lognum)) {
            # Reading logs is limited to a maximum chunk size - normally 32K. The chunks are base64 encoded so we
            # need to read a chunk, decode, calculate next offset. Limit loop to 40 runs (max 1MB retrieval)
            for (1..40) {
                my $chunk = IMachine_readLog($$gref{IMachine}, $lognum, $offset, 32768); # Request 32K max. Limit is usually 32K anyway
                last if (!$chunk); # Terminate loop if we've reached the end or log is empty
                $log .= decode_base64($chunk); # Chunk is base64 encoded. Append to log
                $offset = length($log); # Set next offset into log to get the next chunk
            }

            if ($log) {
                if (open(LOG, '>', $logfile)) {
                    print(LOG $log);
                    close(LOG);
                    &addrow_log("Guest log $logfile saved");
                }
                else { &show_err_msg('logsavefailed', "\nFile: $logfile\nError: $!"); }
            }
            else { &show_err_msg('logempty'); }
        }
        else { &show_err_msg('logempty'); }

        &busy_pointer($gui{dialogLog}, 0);
    }
}

# Show the export appliance dialog
sub show_dialog_exportappl {
    my $gref = &getsel_list_guest();
    my $vhost = &vhost();
    my $fname = &rcatdir($$vhost{machinedir}, $$gref{Name});
    $gui{entryExportApplFile}->set_text($fname);
    $gui{entryExportApplName}->set_text($$gref{Name});
    $gui{textbufferExportApplDescription}->set_text(IMachine_getDescription($$gref{IMachine}));

    # Determine if any media are USB attached as they are not supported by Appliances and
    # whether any media encrypted
    my @IMediumAttachment = IMachine_getMediumAttachments($$gref{IMachine});
    my %used_key_ids; # Key IDs can only be asked for once, we keep a used list here

    foreach my $attach (@IMediumAttachment) {
        my $IStorageController = IMachine_getStorageControllerByName($$gref{IMachine}, $$attach{controller});

        if (IStorageController_getBus($IStorageController) eq 'USB') {
            &show_err_msg('exportapplusb');
            return;
        }

        next if (!$$attach{medium}); # Empty DVD drive etc

        if (&imedium_has_property($$attach{medium}, 'CRYPT/KeyStore')) {
            my $keyid = IMedium_getProperty($$attach{medium}, 'CRYPT/KeyId');
            if (!$used_key_ids{$keyid}) {
                my $passwd = &show_dialog_decpasswd($$attach{medium}, $keyid);
                if ($passwd) { $used_key_ids{$keyid} = $passwd; }
                else { return; }
            }
        }
    }

    do {
        my $response = $gui{dialogExportAppl}->run;

        if ($response eq 'ok') {
            # Other entries don't required validation
            if (!$gui{entryExportApplFile}->get_text()) { &show_err_msg('invalidfile'); }
            elsif (!$gui{entryExportApplName}->get_text()) { &show_err_msg('invalidname'); }
            else {
                $gui{dialogExportAppl}->hide;
                my $location = $gui{entryExportApplFile}->get_text() . &getsel_combo($gui{comboboxExportApplFormat}, 2);
                my $IAppliance = IVirtualBox_createAppliance($gui{websn});

                foreach my $key (keys(%used_key_ids)) {
                    IAppliance_addPasswords($IAppliance, $key, $used_key_ids{$key});
                }

                my $IVirtualSystemDescription = IMachine_exportTo($$gref{IMachine}, $IAppliance, $location);
                IVirtualSystemDescription_addDescription($IVirtualSystemDescription, 'Name', $gui{entryExportApplName}->get_text(), '');
                IVirtualSystemDescription_addDescription($IVirtualSystemDescription, 'Product', $gui{entryExportApplProduct}->get_text(), '');
                IVirtualSystemDescription_addDescription($IVirtualSystemDescription, 'ProductUrl', $gui{entryExportApplProductURL}->get_text(), '');
                IVirtualSystemDescription_addDescription($IVirtualSystemDescription, 'Vendor', $gui{entryExportApplVendor}->get_text(), '');
                IVirtualSystemDescription_addDescription($IVirtualSystemDescription, 'VendorUrl', $gui{entryExportApplVendorURL}->get_text(), '');
                IVirtualSystemDescription_addDescription($IVirtualSystemDescription, 'Version', $gui{entryExportApplVersion}->get_text(), '');
                my $iter_s = $gui{textbufferExportApplDescription}->get_start_iter();
                my $iter_e = $gui{textbufferExportApplDescription}->get_end_iter();
                IVirtualSystemDescription_addDescription($IVirtualSystemDescription, 'Description', $gui{textbufferExportApplDescription}->get_text($iter_s, $iter_e, 0), '');
                $iter_s = $gui{textbufferExportApplLicense}->get_start_iter();
                $iter_e = $gui{textbufferExportApplLicense}->get_end_iter();
                IVirtualSystemDescription_addDescription($IVirtualSystemDescription, 'License', $gui{textbufferExportApplLicense}->get_text($iter_s, $iter_e, 0), '');
                # Removed to optional manifest creation because API broke in at least with VB 6.0.0. Cannot pass an empty option and no other options are desirable.
                my $IProgress = IAppliance_write($IAppliance, &getsel_combo($gui{comboboxExportApplFormat}, 1), 'CreateManifest', $location);
                if ($IProgress) { &show_progress_window($IProgress, "Exporting Appliance $$gref{Name}", $gui{img}{ProgressExport}); }
                &addrow_log("Exported $$gref{Name} as an appliance to $location");
            }
        }
        else { $gui{dialogExportAppl}->hide; }

    } until (!$gui{dialogExportAppl}->visible());
}

sub show_dialog_snapshotdetails {
    my $snapref = &getsel_list_snapshots();

    if ($$snapref{ISnapshot}) { # This is needed in case a user double clicks on "Current State" which is not a real snapshot
        $gui{entrySnapshotName}->set_text(ISnapshot_getName($$snapref{ISnapshot}));
        $gui{textbufferSnapshotDescription}->set_text(ISnapshot_getDescription($$snapref{ISnapshot}));
        my $response = $gui{dialogSnapshot}->run;
        $gui{dialogSnapshot}->hide;

        if ($response eq 'ok') {
            my $iter_s = $gui{textbufferSnapshotDescription}->get_start_iter();
            my $iter_e = $gui{textbufferSnapshotDescription}->get_end_iter();
            ISnapshot_setDescription($$snapref{ISnapshot}, $gui{textbufferSnapshotDescription}->get_text($iter_s, $iter_e, 0));
            ISnapshot_setName($$snapref{ISnapshot}, $gui{entrySnapshotName}->get_text());
            &fill_list_guest();
        }
    }
}

sub show_dialog_snapshot {
    my ($widget) = @_; # Need to reuse dialog for snapshot details
    $gui{entrySnapshotName}->set_text('Snapshot');
    $gui{textbufferSnapshotDescription}->set_text('');
    my $response = $gui{dialogSnapshot}->run();
    $gui{dialogSnapshot}->hide();

    if ($response eq 'ok') {
        my $iter_s = $gui{textbufferSnapshotDescription}->get_start_iter();
        my $iter_e = $gui{textbufferSnapshotDescription}->get_end_iter();
        &take_snapshot($gui{entrySnapshotName}->get_text(), $gui{textbufferSnapshotDescription}->get_text($iter_s, $iter_e, 0));
    }
}

# Discards the saved execution state for a guest
sub discard_saved_state {
    my $gref = &getsel_list_guest();
    my $sref = &get_session($$gref{IMachine});

    IMachine_discardSavedState($$sref{IMachine}, 'true');
    &fill_list_guest();
    &addrow_log("Discarded saved execution state of $$gref{Name}.");

    # At this point the guest may have save its state and the session lock automatically released
    ISession_unlockMachine($$sref{ISession}) if (ISession_getState($$sref{ISession}) eq 'Locked');
}

# Performs a reset of the guest
sub reset_guest {
    my $gref = &getsel_list_guest();
    my $sref = &get_session($$gref{IMachine});

    if ($$sref{Lock} eq 'Shared') {
        IConsole_reset(ISession_getConsole($$sref{ISession}));
        &addrow_log("Sent reset signal to $$gref{Name}.");
    }

    ISession_unlockMachine($$sref{ISession}) if (ISession_getState($$sref{ISession}) eq 'Locked');
}

# Stops the guest
sub stop_guest {
    if ($prefs{STOPTYPE} eq 'ACPI') { &stop_guest_acpi(); }
    elsif ($prefs{STOPTYPE} eq 'STATE') { &stop_guest_savestate(); }
    else { &stop_guest_poweroff(); }
}

# Stops a guest by issuing a hard poweroff
sub stop_guest_poweroff {
    my $gref = &getsel_list_guest();
    my $sref = &get_session($$gref{IMachine});

    if ($$sref{Lock} eq 'Shared') {
        my $IConsole = ISession_getConsole($$sref{ISession});

        if (my $IProgress = IConsole_powerDown($IConsole)) { # Not cancellable
            &show_progress_window($IProgress, "Powering off guest $$gref{Name}", $gui{img}{ProgressPowerOff});
            &fill_list_guest();
            &addrow_log("Sent power off signal to $$gref{Name}.");

        }
        else { &addrow_log("WARNING: Could not send power off signal to $$gref{Name}."); }
    }

    # At this point the guest may have saved its state and the session lock automatically released
    ISession_unlockMachine($$sref{ISession}) if (ISession_getState($$sref{ISession}) eq 'Locked');
}

sub stop_guest_acpi {
    my $gref = &getsel_list_guest();
    my $sref = &get_session($$gref{IMachine});

    if ($$sref{Lock} eq 'Shared') {
        IConsole_powerButton(ISession_getConsole($$sref{ISession}));
        &fill_list_guest();
        &addrow_log("Sent ACPI shutdown to $$gref{Name} which may be prompting you to shutdown.");
    }

    # At this point the guest may have powered off and the session lock automatically released.
    ISession_unlockMachine($$sref{ISession}) if (ISession_getState($$sref{ISession}) eq 'Locked');
}

# Stops a guest and save it's execution state
sub stop_guest_savestate {
    my $gref = &getsel_list_guest();
    my $sref = &get_session($$gref{IMachine});

    if ($$sref{Lock} eq 'Shared') {

        if (my $IProgress = IMachine_saveState($$sref{IMachine})) { # Not cancellable
            &show_progress_window($IProgress, "Saving guest execution state of $$gref{Name}", $gui{img}{ProgressStateSave});
            &fill_list_guest();
            &addrow_log("Saved the execution state of $$gref{Name}.");
        }
        else { &addrow_log("WARNING: Could not save the execution state of $$gref{Name}."); }
    }

    # At this point the guest may have save its state and the session lock automatically released
    ISession_unlockMachine($$sref{ISession}) if (ISession_getState($$sref{ISession}) eq 'Locked');
}

# Pauses the execution of the guest
sub pause_guest {
    my $gref = &getsel_list_guest();
    my $sref = &get_session($$gref{IMachine});

    if ($$sref{Lock} eq 'Shared') {
        IConsole_pause(ISession_getConsole($$sref{ISession}));
        &fill_list_guest();
        &addrow_log("Paused the execution of $$gref{Name}.");
    }

    ISession_unlockMachine($$sref{ISession}) if (ISession_getState($$sref{ISession}) eq 'Locked');
}

sub resume_guest {
    my $gref = &getsel_list_guest();
    my $sref = &get_session($$gref{IMachine});

    if ($$sref{Lock} eq 'Shared') {
        IConsole_resume(ISession_getConsole($$sref{ISession}));
        &fill_list_guest();
        &addrow_log("Resumed the execution state of $$gref{Name}.");
    }

    ISession_unlockMachine($$sref{ISession}) if (ISession_getState($$sref{ISession}) eq 'Locked');
}

sub start_guest {
    my $gref = &getsel_list_guest();
    my $ISession = IWebsessionManager_getSessionObject($gui{websn});
    my $IProgress = IMachine_launchVMProcess($$gref{IMachine}, $ISession, 'headless', '');
    my $started = 0;

    if ($IProgress) { # Is Cancellable
        my $resultcode = &show_progress_window($IProgress, "Starting guest $$gref{Name}", $gui{img}{ProgressStart});

        if (IProgress_getCanceled($IProgress) eq 'true') { &addrow_log("Cancelled starting guest $$gref{Name}"); }
        elsif ( $resultcode != 0) {
            my $IVirtualBoxErrorInfo = IProgress_getErrorInfo($IProgress);
            &show_err_msg('startguest', "Guest: $$gref{Name}\nCode: $resultcode\nError:\n" . IVirtualBoxErrorInfo_getText($IVirtualBoxErrorInfo));
        }
        else {
            $started = 1;
            &addrow_log("Start signal sent to $$gref{Name}.");

            # Determine if we have anything encrypted
            my @IMediumAttachment = IMachine_getMediumAttachments($$gref{IMachine});
            my %used_key_ids; # Key IDs can only be asked for once, we keep a used list here

            # Determine if any media are encrypted and prompt for the password
            foreach my $attach (@IMediumAttachment) {
                next if ($$attach{type} ne 'HardDisk');

                if (&imedium_has_property($$attach{medium}, 'CRYPT/KeyStore')) {
                    my $keyid = IMedium_getProperty($$attach{medium}, 'CRYPT/KeyId');
                    if (!$used_key_ids{$keyid}) {
                        my $passwd = &show_dialog_decpasswd($$attach{medium}, $keyid);

                        if ($passwd) {
                            my $gref = &getsel_list_guest();
                            my $sref = &get_session($$gref{IMachine});

                            if ($$sref{Lock} eq 'Shared') {
                                my $IConsole = ISession_getConsole($$sref{ISession});
                                IConsole_addDiskEncryptionPassword($IConsole, $keyid, $passwd, 0);
                            }

                            ISession_unlockMachine($$sref{ISession}) if (ISession_getState($$sref{ISession}) eq 'Locked');
                            $used_key_ids{$keyid} = $passwd;
                        }
                        else {
                            $started = 0;
                            &stop_guest_poweroff();
                        }
                    }
                }
            }
        }
    }
    else { &show_err_msg('sessionopen', " ($$gref{Name})"); }

    ISession_unlockMachine($ISession) if (ISession_getState($ISession) ne 'Unlocked');
    &open_remote_display() if ($prefs{RDPAUTOOPEN} and $started);
    &fill_list_guest() if ($started);
}

# Removes a guest, optionally deleting associated files
sub remove_guest {
    my $gref = &getsel_list_guest();
    my $response = $gui{dialogRemoveGuest}->run;
    $gui{dialogRemoveGuest}->hide;

    if ($response eq '1') { # Remove Only
        IMachine_unregister($$gref{IMachine}, 'DetachAllReturnNone');
        unlink("$gui{THUMBDIR}/$$gref{Uuid}.png") if (-e "$gui{THUMBDIR}/$$gref{Uuid}.png"); # Remove screenshot icon
        &addrow_log("Removed $$gref{Name}.");
        &fill_list_guest();
    }
    elsif ($response eq '2') { # Delete all
        my @IMedium = IMachine_unregister($$gref{IMachine}, 'DetachAllReturnHardDisksOnly');

        foreach my $medium (@IMedium) { # Is cancellable
            my $IProgress = IMachine_deleteConfig($$gref{IMachine}, $medium);
            &show_progress_window($IProgress, 'Deleting hard disk image', $gui{img}{ProgressMediaDelete});
            if (IProgress_getCanceled($IProgress) eq 'true') { &addrow_log("Cancelled hard disk deletion"); }
        }

        unlink("$gui{THUMBDIR}/$$gref{Uuid}.png") if (-e "$gui{THUMBDIR}/$$gref{Uuid}.png"); # Remove screenshot icon
        &addrow_log("Removed and deleted $$gref{Name}.");
        &fill_list_guest();
    }
}

# Restores a guest to a snapshot state
sub restore_snapshot {
    my $gref = &getsel_list_guest();
    my $sref = &get_session($$gref{IMachine});

    if ($$sref{Type} eq 'WriteLock') { # Not cancellable
        my $snapref = &getsel_list_snapshots();
        my $IProgress = IMachine_restoreSnapshot($$sref{IMachine}, $$snapref{ISnapshot});
        &show_progress_window($IProgress, 'Restoring snapshot', $gui{img}{ProgressSnapshotRestore});
        &addrow_log("Snapshot of $$gref{Name} restored.");
    }
    else { &show_err_msg('restorefail', " ($$gref{Name})"); }

    ISession_unlockMachine($$sref{ISession}) if (ISession_getState($$sref{ISession}) eq 'Locked');
    &fill_list_guest(); # This also refreshes the snapshot list
}

# Deletes a guest snapshot
sub delete_snapshot {
    my $gref = &getsel_list_guest();
    my $sref = &get_session($$gref{IMachine});

    if ($$sref{Lock} ne 'None') {
        my $snapref = &getsel_list_snapshots();

        if (ISnapshot_getChildrenCount($$snapref{ISnapshot}) > 1) { &show_err_msg('snapdelchild', " ($$gref{Name})"); }
        else { # Not cancellable
            my $snapuuid = ISnapshot_getId($$snapref{ISnapshot});
            my $IProgress = IMachine_deleteSnapshot($$sref{IMachine}, $snapuuid);
            &show_progress_window($IProgress, 'Deleting snapshot', $gui{img}{ProgressSnapshotDiscard}) if ($IProgress);
            &addrow_log("Snapshot of $$gref{Name} deleted.");
        }
    }
    else { &show_err_msg('snapdelete', " ($$gref{Name})"); }

    ISession_unlockMachine($$sref{ISession}) if (ISession_getState($$sref{ISession}) eq 'Locked');
    &fill_list_guest(); # This also refreshes the snapshot list
}

# Takes a snapshot of a guest
sub take_snapshot {
    my ($name, $description) = @_;
    $name = 'Snapshot' if (!$name);
    my $gref = &getsel_list_guest();
    my $sref = &get_session($$gref{IMachine});

    if ($$sref{Lock} ne 'None') { # Not cancellable
        my ($snapid, $IProgress) = IMachine_takeSnapshot($$sref{IMachine}, $name, $description, 'true');
        &show_progress_window($IProgress, 'Taking snapshot', $gui{img}{ProgressSnapshotCreate}) if ($IProgress);
        &addrow_log("Created a new snapshot of $$gref{Name}.");
    }
    else { &show_err_msg('snapshotfail', " ($$gref{Name})"); }

    ISession_unlockMachine($$sref{ISession}) if (ISession_getState($$sref{ISession}) eq 'Locked');
    &fill_list_guest(); # This also refreshes the snapshot list
}

# Attempts to open the remote display by calling the RDP client
sub open_remote_display {
    my $vhost = &vhost();
    my $gref = &getsel_list_guest();
    my $sref = &get_session($$gref{IMachine});

    if ($$sref{Lock} eq 'Shared') {
        my $IConsole = ISession_getConsole($$sref{ISession});
        my $IVRDEServerInfo = IConsole_getVRDEServerInfo($IConsole);

        for (1..5) { # Wait up to 5 seconds for the VRDE server to start
            last if ($$IVRDEServerInfo{port} != -1);
            $IVRDEServerInfo = IConsole_getVRDEServerInfo($IConsole);
            sleep 1;
        }

        if ($$IVRDEServerInfo{port} > 0) {
            my $dispcmd = $prefs{RDPCLIENT};
            $dispcmd = $prefs{VNCCLIENT} if ($$vhost{vrdeextpack} =~ m/vnc/i);

            my ($user, $pass) = ($gui{entryConnectUser}->get_text(), $gui{entryConnectPassword}->get_text());
            my $dst = $endpoint;
            $dst =~ s/^.*:\/\///;
            $dst =~ s/:\d+$//;
            $dispcmd =~ s/%h/$dst/g;
            $dispcmd =~ s/%p/$$IVRDEServerInfo{port}/g;
            $dispcmd =~ s/%n/$$gref{Name}/g;
            $dispcmd =~ s/%o/$$gref{Os}/g;
            $dispcmd =~ s/%U/$user/g;
            $dispcmd =~ s/%P/$pass/g;
            $dispcmd =~ s/%X/$prefs{AUTOHINTDISPX}/g;
            $dispcmd =~ s/%Y/$prefs{AUTOHINTDISPY}/g;
            $dispcmd =~ s/%D/$prefs{AUTOHINTDISPD}/g;

            if ($prefs{AUTOHINTDISP}) {
                my $IConsole = ISession_getConsole($$sref{ISession});
                IDisplay_setVideoModeHint(IConsole_getDisplay($IConsole), 0, 1, 0, 0, 0, $prefs{AUTOHINTDISPX}, $prefs{AUTOHINTDISPY}, $prefs{AUTOHINTDISPD});
                &addrow_log("Sent video hint ($prefs{AUTOHINTDISPX}x$prefs{AUTOHINTDISPY}:$prefs{AUTOHINTDISPD}) to $$gref{Name}.");
            }

            ($^O =~ m/MSWin/) ? $dispcmd .= ' >nul' : $dispcmd .= ' &';
            system("$dispcmd");
            &addrow_log("Calling: $dispcmd");
            &addrow_log("Request to open remote display for $$gref{Name} at address $dst:$$IVRDEServerInfo{port}");
        }
        else { &show_err_msg('remotedisplay', " ($$gref{Name})"); }
    }

    ISession_unlockMachine($$sref{ISession}) if (ISession_getState($$sref{ISession}) eq 'Locked');
}

# Displays a popup machine menu on the guest list when the right mouse button is pressed
sub show_rmb_menu {
    my ($widget, $event) = @_;

    # Check if it's the RMB otherwise do nothing
    if ($event->button == 3) {
        # This code is needed because if the user just presses the RMB, then GTK has not updated the
        # location of the cursor until AFTER this routine is complete meaning we will be referencing the
        # wrong VM. We need to force a cursor update first.
        my $path = $gui{treeviewGuest}->get_path_at_pos(int($event->x), int($event->y));
        if ($path) {
            $gui{treeviewGuest}->grab_focus();
            $gui{treeviewGuest}->set_cursor($path);
        }

        $gui{menuMachine}->popup(undef, undef, undef, undef, 0, $event->time);
        return 1;
    }

    return 0;
}

# Called when parent DVD menu is highlighted. Cheaper than calling each time main menu is opened
sub fill_menu_dvd {
    my $vhost = &vhost();
    my $dvdmenu = Gtk2::Menu->new();
    $gui{menuitemDVD}->set_submenu(undef); # Help garbage collection
    $gui{menuitemDVD}->set_submenu($dvdmenu); # Hijack the temporary submenu (restored on exit)
    my $IMediumRef = &get_all_media('DVD');
    my $item = Gtk2::MenuItem->new_with_label('<Empty Drive>');
    $dvdmenu->append($item);
    $item->show();
    $item->signal_connect(activate => \&mount_dvd_online, '');
    my $sep = Gtk2::SeparatorMenuItem->new();
    $dvdmenu->append($sep);
    $sep->show();

    if ($$vhost{dvd}) {
        foreach my $pdvd (@{$$vhost{dvd}}) {
            my $item = Gtk2::MenuItem->new_with_label('<Server Drive> ' . IMedium_getLocation($pdvd));
            $dvdmenu->append($item);
            $item->show();
            $item->signal_connect(activate => \&mount_dvd_online, $pdvd);
        }

        my $pdvdsep = Gtk2::SeparatorMenuItem->new();
        $dvdmenu->append($pdvdsep);
        $pdvdsep->show();
    }

    foreach (sort { lc($$IMediumRef{$a}) cmp lc($$IMediumRef{$b}) } (keys %$IMediumRef)) {
        my $item = Gtk2::MenuItem->new_with_label($$IMediumRef{$_});
        $dvdmenu->append($item);
        $item->show();
        $item->signal_connect(activate => \&mount_dvd_online, $_);
    }
}

# Called when parent USB menu is highlighted. Cheaper than calling each time machine menu is opened
sub fill_menu_usb {
    my %connected;
    my $gref = &getsel_list_guest();
    my $sref = &get_session($$gref{IMachine});

    if ($$sref{Lock} eq 'Shared') {
        my $usbmenu = Gtk2::Menu->new();
        $gui{menuitemUSB}->set_submenu(undef); # Help garbage collection
        $gui{menuitemUSB}->set_submenu($usbmenu); # Hijack the temporary submenu (restored on exit)
        my @IHostUSBDevices = IHost_getUSBDevices(IVirtualBox_getHost($gui{websn}));
        my @USBDevices = IConsole_getUSBDevices(ISession_getConsole($$sref{ISession}));

        foreach my $IUSBDevice (@USBDevices) { $connected{IUSBDevice_getId($IUSBDevice)} = 1; }

        foreach my $usb (@IHostUSBDevices) {
            my $label = &usb_make_label(IUSBDevice_getManufacturer($usb),
                                        IUSBDevice_getProduct($usb),
                                        sprintf('%04x', IUSBDevice_getRevision($usb)));

            my $item = Gtk2::CheckMenuItem->new_with_label($label);
            my $usbid = IUSBDevice_getId($usb);
            $item->set_active(1) if $connected{$usbid};
            $usbmenu->append($item);
            $item->show();
            $item->signal_connect(activate => \&mount_usb_online, [$usbid, $label]);
        }
    }

    ISession_unlockMachine($$sref{ISession}) if (ISession_getState($$sref{ISession}) eq 'Locked');
}

# Fills the menu with the number of hot pluggable CPUs
sub fill_menu_cpu {
    my $gref = &getsel_list_guest();
    my $sref = &get_session($$gref{IMachine});

    if ($$sref{Lock} eq 'Shared') {
        my $cpumenu = Gtk2::Menu->new();
        $gui{menuitemHotPlugCPU}->set_submenu(undef); # Help garbage collection
        $gui{menuitemHotPlugCPU}->set_submenu($cpumenu); # Hijack the temporary submenu (restored on exit)
        my $cpucount = IMachine_getCPUCount($$sref{IMachine});

        # CPU 0 is special - it can never be detached.
        my $item = Gtk2::CheckMenuItem->new_with_label('vCPU 0');
        $item->set_active(1);
        $item->set_sensitive(0);
        $item->set_tooltip_text('vCPU 0 is never hot pluggable');
        $cpumenu->append($item);
        $item->show();

        foreach my $cpunum (1..($cpucount - 1)) {
            my $item = Gtk2::CheckMenuItem->new_with_label("vCPU $cpunum");
            $item->set_active(1) if (&bl(IMachine_getCPUStatus($$sref{IMachine}, $cpunum)));
            $cpumenu->append($item);
            $item->show();
            $item->signal_connect(activate => \&mount_cpu_online, $cpunum);
        }
    }

    ISession_unlockMachine($$sref{ISession}) if (ISession_getState($$sref{ISession}) eq 'Locked');
}

# Attaches or detaches a processor whilst the guest is online
sub mount_cpu_online {
    my ($widget, $cpunum) = @_;
    my $gref = &getsel_list_guest();
    my $sref = &get_session($$gref{IMachine});

    if ($$sref{Lock} eq 'Shared') {
        if ($widget->get_active()) {
            IMachine_hotPlugCPU($$sref{IMachine}, $cpunum);
            &addrow_log("Attempt to hot plug vCPU $cpunum for $$gref{Name}.");
        }
        else {
            IMachine_hotUnplugCPU($$sref{IMachine}, $cpunum);
            &addrow_log("Attempt to hot unplug vCPU $cpunum for $$gref{Name}.");
        }

        IMachine_saveSettings($$sref{IMachine});
    }
    else { &addrow_log("Error: Could not change the status of CPU $cpunum for $$gref{Name}."); }

    ISession_unlockMachine($$sref{ISession}) if (ISession_getState($$sref{ISession}) eq 'Locked');
}

# Attaches or detaches a USB device whilst the guest is online
sub mount_usb_online {
    my ($widget, $dataref) = @_;
    my $gref = &getsel_list_guest();
    my $sref = &get_session($$gref{IMachine});

    if ($$sref{Lock} eq 'Shared') {
        my $IConsole = ISession_getConsole($$sref{ISession});

        if ($widget->get_active()) {
            IConsole_attachUSBDevice($IConsole, $$dataref[0]);
            &addrow_log("Attached USB device '$$dataref[1]' to $$gref{Name}.");
        }
        else {
            IConsole_detachUSBDevice($IConsole, $$dataref[0]);
            &addrow_log("Detached USB device '$$dataref[1]' from $$gref{Name}.");
        }

        IMachine_saveSettings($$sref{IMachine});
    }

    ISession_unlockMachine($$sref{ISession}) if (ISession_getState($$sref{ISession}) eq 'Locked');
}

# Called when parent Floppy menu is highlighted. Cheaper than calling each time machine menu is opened
sub fill_menu_floppy {
    my $vhost = &vhost();
    my $floppymenu = Gtk2::Menu->new();
    $gui{menuitemFloppy}->set_submenu(undef); # Help garbage collection
    $gui{menuitemFloppy}->set_submenu($floppymenu); # Hijack the temporary submenu (restored on exit)
    my $IMediumRef = &get_all_media('Floppy');
    my $item = Gtk2::MenuItem->new_with_label('<Empty Drive>');
    $floppymenu->append($item);
    $item->show();
    $item->signal_connect(activate => \&mount_floppy_online, '');
    my $sep = Gtk2::SeparatorMenuItem->new();
    $floppymenu->append($sep);
    $sep->show();

    if ($$vhost{floppy}) {
        foreach my $pfloppy (@{$$vhost{floppy}}) {
            my $item = Gtk2::MenuItem->new_with_label('<Server Drive> ' . IMedium_getLocation($pfloppy));
            $floppymenu->append($item);
            $item->show();
            $item->signal_connect(activate => \&mount_floppy_online, $pfloppy);
        }

        my $pfloppysep = Gtk2::SeparatorMenuItem->new();
        $floppymenu->append($pfloppysep);
        $pfloppysep->show();
    }

    foreach (sort { lc($$IMediumRef{$a}) cmp lc($$IMediumRef{$b}) } (keys %$IMediumRef)) {
        my $item = Gtk2::MenuItem->new_with_label($$IMediumRef{$_});
        $floppymenu->append($item);
        $item->show();
        $item->signal_connect(activate => \&mount_floppy_online, $_);
    }
}

# Inserts a DVD/CD whilst the guest is online and running
sub mount_dvd_online {
    my ($widget, $IMedium) = @_;
    my $gref = &getsel_list_guest();
    my $sref = &get_session($$gref{IMachine});

    if ($$sref{Lock} eq 'Shared') {
        my @IMediumAttachment = IMachine_getMediumAttachments($$sref{IMachine});
        foreach my $attach (@IMediumAttachment) {
            next if ($$attach{type} ne 'DVD');
            IMachine_mountMedium($$sref{IMachine}, $$attach{controller}, $$attach{port}, $$attach{device}, $IMedium, 0);
            last;
        }
        IMachine_saveSettings($$sref{IMachine});
        &addrow_log("Changed optical medium for $$gref{Name}.");
    }

    ISession_unlockMachine($$sref{ISession}) if (ISession_getState($$sref{ISession}) eq 'Locked');
}

# Inserts a floppy disk image whilst the guest is online
sub mount_floppy_online {
    my ($widget, $IMedium) = @_;
    my $gref = &getsel_list_guest();
    my $sref = &get_session($$gref{IMachine});

    if ($$sref{Lock} eq 'Shared') {
        my @IMediumAttachment = IMachine_getMediumAttachments($$sref{IMachine});
        foreach my $attach (@IMediumAttachment) {
            next if ($$attach{type} ne 'Floppy');
            IMachine_mountMedium($$sref{IMachine}, $$attach{controller}, $$attach{port}, $$attach{device}, $IMedium, 0);
            last;
        }
        IMachine_saveSettings($$sref{IMachine});
        &addrow_log("Changed floppy medium for $$gref{Name}.");
    }

    ISession_unlockMachine($$sref{ISession}) if (ISession_getState($$sref{ISession}) eq 'Locked');
}

sub keyboard_CAD {
    my $gref = &getsel_list_guest();
    my $sref = &get_session($$gref{IMachine});

    if ($$sref{Lock} eq 'Shared') {
        my $IKeyboard = IConsole_getKeyboard(ISession_getConsole($$sref{ISession}));
        IKeyboard_putCAD($IKeyboard);
        &addrow_log("Keyboard sequence Ctrl-Alt-Delete sent to $$gref{Name}.");
    }

    ISession_unlockMachine($$sref{ISession}) if (ISession_getState($$sref{ISession}) eq 'Locked');
}

# Attempts to release any pressed keys if the host and the guest become out of sync
sub keyboard_releasekeys {
    my ($widget) = @_;
    my $gref = &getsel_list_guest();
    my $sref = &get_session($$gref{IMachine});

    if ($$sref{IMachine}) {
        my $IKeyboard = IConsole_getKeyboard(ISession_getConsole($$sref{ISession}));
        IKeyboard_releaseKeys($IKeyboard);
        &addrow_log("Keyboard release keys to $$gref{Name}.");
    }

    ISession_unlockMachine($$sref{ISession}) if (ISession_getState($$sref{ISession}) eq 'Locked');
}

# Sends a sequence of keyboard scan codes depending on the option chosen
sub keyboard_send {
    my ($widget, $scancodes) = @_;
    my $gref = &getsel_list_guest();
    my $sref = &get_session($$gref{IMachine});

    if ($$sref{IMachine}) {
        my $IKeyboard = IConsole_getKeyboard(ISession_getConsole($$sref{ISession}));
        IKeyboard_putScancode($IKeyboard, $_) foreach (@{$$scancodes{codes}});
        &addrow_log("Keyboard sequence $$scancodes{desc} sent to $$gref{Name}.");
    }

    ISession_unlockMachine($$sref{ISession}) if (ISession_getState($$sref{ISession}) eq 'Locked');
}

# Updates the video memory requirement when choosing a custom video hint
sub update_vidmeminfo {
    my $w = $gui{spinbuttonCustomVideoW}->get_value_as_int();
    my $h = $gui{spinbuttonCustomVideoH}->get_value_as_int();
    my $d = &getsel_combo($gui{comboboxCustomVideoD}, 1);
    $gui{labelCustomVideoInfo}->set_text('This resolution requires a minimum of ' . &vram_needed($w, $h, $d) . "MB of video memory");
}

# Sends a video mode hint to the guest
sub send_video_hint {
    my ($widget, $res) = @_;
    my $gref = &getsel_list_guest();
    my $sref = &get_session($$gref{IMachine});

    if ($widget eq $gui{menuitemSetVideoCustom}) { $res = &show_dialog_videohint(); }

    if ($$sref{IMachine}) {
        my $IConsole = ISession_getConsole($$sref{ISession});
        IDisplay_setVideoModeHint(IConsole_getDisplay($IConsole), 0, 1, 0, 0, 0, $$res[0], $$res[1], $$res[2]);
        &addrow_log("Sent video hint ($$res[0]x$$res[1]:$$res[2]) to $$gref{Name}.");
    }

    ISession_unlockMachine($$sref{ISession}) if (ISession_getState($$sref{ISession}) eq 'Locked');
}

# Return a hash reference with name as key. Useful for sorting
sub get_all_media {
    my ($type) = @_;
    my @IMedium;
    my %media;

    if ($type eq 'DVD') { @IMedium = IVirtualBox_getDVDImages($gui{websn}); }
    elsif ($type eq 'Floppy') { @IMedium = IVirtualBox_getFloppyImages($gui{websn}); }
    else { @IMedium = IVirtualBox_getHardDisks($gui{websn}); }

    $media{$_} = IMedium_getName($_) foreach (@IMedium);
    return \%media;
}

# Return an appropriate session
sub get_session {
    my ($IMachine) = @_;
    my $ISession = IWebsessionManager_getSessionObject($gui{websn});
    my %state = (Lock     => 'None',
                 Type     => 'None',
                 IMachine => 0,
                 ISession => 0);

    if (IMachine_getSessionState($IMachine)  eq 'Unlocked') {
        IMachine_lockMachine($IMachine, $ISession, 'VM');
        $state{Lock} = 'VM';
        $state{Type} = ISession_getType($ISession);
        $state{IMachine} = ISession_getMachine($ISession);
        $state{ISession} = $ISession;
    }
    elsif (IMachine_getSessionState($IMachine)  eq 'Locked') {
        # Theoretically we shouldn't return a writelock here because it should have already been locked
        IMachine_lockMachine($IMachine, $ISession, 'Shared');
        $state{Lock} = 'Shared';
        $state{Type} = ISession_getType($ISession);
        $state{IMachine} = ISession_getMachine($ISession);
        $state{ISession} = $ISession;
    }

    return \%state;
}

# Encrypts a hard disk image. *MUST* only be given hard disk images
sub encrypt_disk {
    my ($IMedium, $currentpasswd, $cipher, $newpasswd, $passwdid) = @_;
    my $name = IMedium_getName($IMedium);

    # Not allowed to have children
    if (IMedium_getChildren($IMedium)) {
        &addrow_log("The Medium $name cannot be encrypted because it has child media.");
        return 1;
    }

    # Only allowed to be attached to 1 machine or fewer
    my @mids = IMedium_getMachineIds($IMedium);

    if (scalar(@mids) > 1) {
        &addrow_log("The Medium $name cannot be encrypted because it is attached to more than 1 guest");
        return 1;
    }

    my $IProgress = IMedium_changeEncryption($IMedium, $currentpasswd, $cipher, $newpasswd, $passwdid);
    &addrow_log("Enrypting the disk image $name with $cipher.");
    &show_progress_window($IProgress, "Encrypting Disk Image $name");

    return 0;
}

# Returns whether the IMedium object has a particular property.
# uses getProperties to avoid VirtualBox from issuing an error when
# other methods would.
sub imedium_has_property {
    my ($IMedium, $property) = @_;
    my @properties = IMedium_getProperties($IMedium, undef); # Note, SDK states second parameter is ignored
    return (grep($property, @properties));
}

# Set sensitivity based on connection state
sub sens_connect {
    my ($state) = @_;
    $gui{menuitemNew}->set_sensitive($state);
    $gui{menuitemAdd}->set_sensitive($state);
    $gui{menuitemImportAppl}->set_sensitive($state);
    $gui{menuitemVMM}->set_sensitive($state);
    $gui{menuitemHostNetMan}->set_sensitive($state);
    $gui{menuitemServerInfo}->set_sensitive($state);
    $gui{menuitemVBPrefs}->set_sensitive($state);
    $gui{toolbuttonNew}->set_sensitive($state);
    $gui{toolbuttonRefresh}->set_sensitive($state);
    $gui{progressbarMem}->show();
}

# Sets the sensitivity when no guest is selected
sub sens_unselected {
    $gui{menuitemExportAppl}->set_sensitive(0);
    $gui{menuitemAction}->set_sensitive(0);
    $gui{menuitemStart}->set_sensitive(0);
    $gui{menuitemStop}->set_sensitive(0);
    $gui{menuitemPause}->set_sensitive(0);
    $gui{menuitemResume}->set_sensitive(0);
    $gui{menuitemSettings}->set_sensitive(0);
    $gui{menuitemClone}->set_sensitive(0);
    $gui{menuitemSetGroup}->set_sensitive(0);
    $gui{menuitemUngroup}->set_sensitive(0);
    $gui{menuitemDiscard}->set_sensitive(0);
    $gui{menuitemReset}->set_sensitive(0);
    $gui{menuitemRemove}->set_sensitive(0);
    $gui{menuitemKeyboard}->set_sensitive(0);
    $gui{menuitemDisplay}->set_sensitive(0);
    $gui{menuitemHotPlugCPU}->set_sensitive(0);
    $gui{menuitemDVD}->set_sensitive(0);
    $gui{menuitemFloppy}->set_sensitive(0);
    $gui{menuitemUSB}->set_sensitive(0);
    $gui{menuitemScreenshot}->set_sensitive(0);
    $gui{menuitemLogs}->set_sensitive(0);
    $gui{toolbuttonStart}->set_sensitive(0);
    $gui{toolbuttonStop}->set_sensitive(0);
    $gui{toolbuttonSettings}->set_sensitive(0);
    $gui{toolbuttonRemoteDisplay}->set_sensitive(0);
    $gui{toolbuttonCAD}->set_sensitive(0);
    $gui{toolbuttonDiscard}->set_sensitive(0);
    $gui{toolbuttonReset}->set_sensitive(0);
    $gui{buttonRefreshSnapshot}->set_sensitive(0);
    $gui{buttonCloneSnapshot}->set_sensitive(0);
    $gui{buttonTakeSnapshot}->set_sensitive(0);
}

# Resets the guest icon back to the default
sub reset_icon {
    my $gref = &getsel_list_guest();
    unlink("$gui{THUMBDIR}/$$gref{Uuid}.png") if (-e "$gui{THUMBDIR}/$$gref{Uuid}.png");
    &fill_list_guest();
}

# Takes a PNG screenshot of the guest
sub screenshot {
    my ($widget) = @_;
    my $gref = &getsel_list_guest();
    my $sref = &get_session($$gref{IMachine});
    $gui{filechooserscreenshot}->set_current_name("$$gref{Name}_screenshot.png");
    $gui{filechooserscreenshot}->set_current_folder($ENV{HOME}) if ($ENV{HOME});
    my $response = $gui{filechooserscreenshot}->run();
    $gui{filechooserscreenshot}->hide();
    my $filename = $gui{filechooserscreenshot}->get_filename();

    if ($response eq 'ok' and $filename) {

        if ($$sref{Lock} eq 'Shared') {
            my $IConsole = ISession_getConsole($$sref{ISession});
            my $IDisplay = IConsole_getDisplay($IConsole);
            my ($w, $h, $d, $ox, $oy) = IDisplay_getScreenResolution($IDisplay, 0);
            if (my $rawscreenshot = IDisplay_takeScreenShotToArray($IDisplay, 0, $w, $h, 'PNG')) {
                my $screenshot = decode_base64($rawscreenshot);
                if (open(SHOT, '>', $filename)) {
                    binmode SHOT; # Not normally needed for UNIX, but more portable
                    print SHOT $screenshot;
                    close(SHOT);
                    &fill_list_guest();
                    &addrow_log("Saved screenshot of $$gref{Name} as $filename.");
                }
                else { &addrow_log("Failed to save screenshot of $$gref{Name} as $filename."); }
            }
            else { &show_err_msg('noscreenshot'); }
        }
    }

    ISession_unlockMachine($$sref{ISession}) if (ISession_getState($$sref{ISession}) eq 'Locked');
}

# Sets the guest icon to a screenshot of the guest
sub screenshot_to_icon {
    my ($widget) = @_;
    my $gref = &getsel_list_guest();
    my $sref = &get_session($$gref{IMachine});

    if ($$sref{Lock} eq 'Shared') {
        my $IConsole = ISession_getConsole($$sref{ISession});
        my $IDisplay = IConsole_getDisplay($IConsole);

        if (my $rawicon = IDisplay_takeScreenShotToArray($IDisplay, 0, 32, 32, 'PNG')) {
            mkdir($gui{THUMBDIR}, 0755) unless (-e $gui{THUMBDIR});
            my $icon = decode_base64($rawicon);
            if (open(ICON, '>', "$gui{THUMBDIR}/$$gref{Uuid}.png")) {
                binmode ICON; # Not normally needed for UNIX, but more portable
                print ICON $icon;
                close(ICON);
                &fill_list_guest();
                &addrow_log("Configured screenshot as icon for $$gref{Name}.");
            }
            else { &addrow_log("WARNING: Could not save icon for $$gref{Name}."); }
        }
        else { &show_err_msg('noscreenshot'); }
    }

    ISession_unlockMachine($$sref{ISession}) if (ISession_getState($$sref{ISession}) eq 'Locked');
}

sub group_list_expand {
    $gui{treeviewGuest}->expand_all();
    $prefs{GUESTLISTEXPAND}=1;
    &rbprefs_save();
}

sub group_list_collapse {
    $gui{treeviewGuest}->collapse_all();
    $prefs{GUESTLISTEXPAND}=0;
    &rbprefs_save();
}

# Shows the dialog for importing an appliance
sub show_dialog_importappl {
    do {
        my $response = $gui{dialogImportAppl}->run;

        if ($response eq 'ok') {
            # API broke in at least with VB 6.0.0. You MUST specifiy at least 1 option, so use something harmless-ish. Cannot pass an empty option
            my $importopts = ($gui{checkbuttonImportApplToVDI}->get_active() == 1) ? 'ImportToVDI': 'KeepAllMACs';

            if (!$gui{entryImportApplFile}->get_text()) { &show_err_msg('invalidfile'); }
            else {
                $gui{dialogImportAppl}->hide;
                my $appliancefile = $gui{entryImportApplFile}->get_text();
                &addrow_log("Importing appliance from $appliancefile");
                my $IAppliance = IVirtualBox_createAppliance($gui{websn});
                my $IProgress = IAppliance_read($IAppliance, $appliancefile);

                if ($IProgress) {
                    &show_progress_window($IProgress, 'Reading Appliance', $gui{img}{ProgressReadAppl});
                    IAppliance_interpret($IAppliance);
                    my $warnings = IAppliance_getWarnings($IAppliance);
                    &addrow_log("Import warnings: $warnings") if ($warnings);
                    $IProgress = IAppliance_importMachines($IAppliance, $importopts);

                    if ($IProgress) {
                        &show_progress_window($IProgress, 'Importing Appliance', $gui{img}{ProgressImport});
                        my @appluuid = IAppliance_getMachines($IAppliance);
                        foreach my $id (@appluuid) {
                            &makesel_list_guest($id); # Make the current selection the new appliance
                            &fill_list_guest(); # Repopulate the guest list so it appears and is selected
                            &addrow_log("Imported new appliance from $appliancefile");
                            &show_dialog_edit(); # Edit any settings
                        }
                    }
                    else { &show_err_msg('applimport', "\nAppliance: $appliancefile"); }
                }
                else { &show_err_msg('applimport', "\nAppliance: $appliancefile"); }
            }
        }
        else { $gui{dialogImportAppl}->hide; }

    } until (!$gui{dialogImportAppl}->visible());
}

# Displays the dialog for entering a decryption password
sub show_dialog_decpasswd {
    my ($IMedium, $keyid) = @_;
    my $passwd;
    $gui{labelEnterDecPasswdID}->set_text("Key ID: $keyid");
    $gui{labelEnterDecPasswdName}->set_text("Disk Name: " . IMedium_getName($IMedium));

    my $response = $gui{dialogEnterDecPasswd}->run;
    $gui{dialogEnterDecPasswd}->hide;

    if ($response eq 'ok') { $passwd = $gui{entryEnterDecPasswd}->get_text(); }

    return $passwd;
}

# Displays the dialog for setting a guests group
sub show_dialog_group {
    my $gref = &getsel_list_guest();
    my $sref = &get_session($$gref{IMachine});

    if ($$sref{Lock} ne 'None') {
        my ($group) = IMachine_getGroups($$sref{IMachine}, ('/')); # Only interested in first group entry
        $gui{entrySetGroupGroup}->set_text($group);

        my $response = $gui{dialogSetGroup}->run;
        $gui{dialogSetGroup}->hide;

        if ($response eq 'ok') {
            $group = $gui{entrySetGroupGroup}->get_text();
            $group =~ s/\/+$//; # Remove any traling slashes
            $group = "/$group" if ($group !~ m/^\//);
            IMachine_setGroups($$sref{IMachine}, ($group));
            IMachine_saveSettings($$sref{IMachine});
            &fill_list_guest();
            &addrow_log("Set group membership for $$gref{Name} to $group.");
        }
    }

    ISession_unlockMachine($$sref{ISession}) if (ISession_getState($$sref{ISession}) eq 'Locked');
}

sub clear_group {
    &busy_pointer($gui{windowMain}, 1);
    my $gref = &getsel_list_guest();
    my $sref = &get_session($$gref{IMachine});

    if ($$sref{Lock} ne 'None') {
        IMachine_setGroups($$sref{IMachine}, ('/'));
        IMachine_saveSettings($$sref{IMachine});
        &fill_list_guest();
        &addrow_log("Ungrouped $$gref{Name}.");
    }

    ISession_unlockMachine($$sref{ISession}) if (ISession_getState($$sref{ISession}) eq 'Locked');
    &busy_pointer($gui{windowMain}, 0);
}

# Update the server memory progress bar
sub update_server_membar {
    if ($gui{websn}) {
        my $IHost = IVirtualBox_getHost($gui{websn});
        my $memsize = IHost_getMemorySize($IHost);
        my $memavail = IHost_getMemoryAvailable($IHost);
        my $memused = ($memsize - $memavail);
        $gui{progressbarMem}->set_text("Memory ($memsize MB): $memused MB Used / $memavail MB Free");
        $gui{progressbarMem}->set_fraction(($memused / $memsize));
    }
    return 1; # Return 1 to stop the timer from being removed
}

# Shows the PDF manual when the option is selected. Uses the user's default
# PDF reader via xdg-open on UNIX/BSD/Linux or open on Mac OS X
sub show_manual {
    if ($^O =~ m/darwin/i) { system(qq[open "$docdir/remotebox.pdf" &]); }
    elsif ($^O =~ m/MSWin/) {
        my $windocdir = File::Spec::Win32->canonpath($docdir);
        system(qq[start "RemoteBox Manual" /D "$windocdir" "remotebox.pdf"]);
    }
    else { system(qq[xdg-open "$docdir/remotebox.pdf" &]); }
}

# Display extended details when a guest is selected
sub extended_details {
    $prefs{EXTENDEDDETAILS} = $gui{checkbuttonShowDetails}->get_active();
    &rbprefs_save();
    # Force a refresh if there's a selected guest
    my $model = $gui{treeviewGuest}->get_model();
    my $iter = $gui{treeviewGuest}->get_selection->get_selected() ? $gui{treeviewGuest}->get_selection->get_selected() : 0;
    &onsel_list_guest() if ($iter);
}

sub set_connection_prof_inactive() { $gui{comboboxConnectProfile}->set_active(-1); }

1;
