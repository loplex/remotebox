# List Handling
use strict;
use warnings;
our (%gui, %vmc, %signal, %prefs);

# Block for filling in guest details
{

    # This two subs might be able to be replaced with a single one
    sub expand_details_row {
        my ($treeview, $treeiter, $treepath) = @_;
        my $model = $treeview->get_model();
        my @row = $model->get($treeiter);
        $prefs{$row[5]} = 1;
    }

    sub collapse_details_row {
        my ($treeview, $treeiter, $treepath) = @_;
        my $model = $treeview->get_model();
        my @row = $model->get($treeiter);
        $prefs{$row[5]} = 0;
    }

    # Fill a brief version of the guest details
    sub fill_list_details_brief {
        &addrow_log("Fetching guest details...");
        $gui{treestoreDetails}->clear();
        my $treemodel = $gui{treeviewDetails}->get_model();
        my $gref = &getsel_list_guest();
        my $iter = &addrow_details(undef, 0, $gui{img}{CatGen}, 1, 'Guest Summary', 3, 800, 4, 0.0, 5, 'EXPANDDETGEN');
        &addrow_details($iter, 1, ' Name:', 2, $$gref{Name});
        &addrow_details($iter, 1, ' Operating System:', 2, IMachine_getOSTypeId($$gref{IMachine}));
        my $mem = IMachine_getMemorySize($$gref{IMachine});
        $mem = ($mem > 1023) ? sprintf("%.2f GB", $mem / 1024) : "$mem MB";
        &addrow_details($iter, 1, ' Base Memory:', 2, $mem);
        &addrow_details($iter, 1, ' Video Memory:', 2, IMachine_getVRAMSize($$gref{IMachine}) . ' MB');
        $gui{treeviewDetails}->expand_row($treemodel->get_path($iter), 1) if ($prefs{EXPANDDETGEN});
        my $desciter = &addrow_details(undef, 0, $gui{img}{CatDesc}, 1, 'Description', 3, 800, 4, 0.0, 5, 'EXPANDDETDESC');
        my $desc = IMachine_getDescription($$gref{IMachine});
        $desc ? &addrow_details($desciter, 1, ' Description:', 2, $desc)
            : &addrow_details($desciter, 1, ' <None>');
        $gui{treeviewDetails}->expand_row($treemodel->get_path($desciter), 1) if ($prefs{EXPANDDETDESC});
        &addrow_log("Guest details retrieved.");
    }

    # Fill the guest details
    sub fill_list_details {
        &addrow_log("Fetching extended guest details...");
        my $vhost = &vhost();
        $gui{treestoreDetails}->clear();
        my $treemodel = $gui{treeviewDetails}->get_model();
        my $gref = &getsel_list_guest();
        my $IVRDEServer = IMachine_getVRDEServer($$gref{IMachine});
        my @IStorageController = IMachine_getStorageControllers($$gref{IMachine});
        my $IAudioAdapter = IMachine_getAudioAdapter($$gref{IMachine});
        my @IUSBController = IMachine_getUSBControllers($$gref{IMachine});
        my $geniter = &addrow_details(undef, 0, $gui{img}{CatGen}, 1, 'General', 3, 800, 4, 0.0, 5, 'EXPANDDETGEN');
        &addrow_details($geniter, 1, ' Name:', 2, $$gref{Name});
        &addrow_details($geniter, 1, ' Operating System:', 2, IMachine_getOSTypeId($$gref{IMachine}));
        $gui{treeviewDetails}->expand_row($treemodel->get_path($geniter), 1) if ($prefs{EXPANDDETGEN});

        my $sysiter = &addrow_details(undef, 0, $gui{img}{CatSys}, 1, 'System', 3, 800, 4, 0.0, 5, 'EXPANDDETSYS');
        my $mem = IMachine_getMemorySize($$gref{IMachine});
        $mem = ($mem > 1023) ? sprintf("%.2f GB", $mem / 1024) : "$mem MB";
        &addrow_details($sysiter, 1, ' Base Memory:', 2, $mem);
        &addrow_details($sysiter, 1, ' Firmware:', 2, IMachine_getFirmwareType($$gref{IMachine}));
        &addrow_details($sysiter, 1, ' Processors:', 2, IMachine_getCPUCount($$gref{IMachine}));
        my $bootorder = '';

        foreach (1..4) {
            my $bdev = IMachine_getBootOrder($$gref{IMachine}, $_);
        $bootorder .= "$bdev  " if ($bdev ne 'Null');
        }

        $bootorder ? &addrow_details($sysiter, 1, ' Boot Order:', 2, $bootorder) : &addrow_details($sysiter, 1, ' Boot Order:', 2, '<None Enabled>');
        my $vtx = '';
        $vtx .= 'VT-x/AMD-V  ' if (IMachine_getHWVirtExProperty($$gref{IMachine}, 'Enabled') eq 'true');
        $vtx .= 'VPID  ' if (IMachine_getHWVirtExProperty($$gref{IMachine}, 'VPID') eq 'true');
        $vtx .= 'PAE/NX  ' if (IMachine_getCPUProperty($$gref{IMachine}, 'PAE') eq 'true');
        $vtx .= 'Nested Paging  ' if (IMachine_getHWVirtExProperty($$gref{IMachine}, 'NestedPaging') eq 'true');
        $vtx ? &addrow_details($sysiter, 1, ' Acceleration:', 2, $vtx) : &addrow_details($sysiter, 1, ' Acceleration:', 2, '<None Enabled>');
        my $paravirt = 'Configured: ' . IMachine_getParavirtProvider($$gref{IMachine}) . ', Effective: ' . IMachine_getEffectiveParavirtProvider($$gref{IMachine});
        #&addrow_details($sysiter, 1, ' Paravirtualization:', 2, IMachine_getParavirtProvider($$gref{IMachine}));

        &addrow_details($sysiter, 1, ' Paravirtualization:', 2, $paravirt);
        $gui{treeviewDetails}->expand_row($treemodel->get_path($sysiter), 1) if ($prefs{EXPANDDETSYS});

        my $dispiter = &addrow_details(undef, 0, $gui{img}{CatDisp}, 1, 'Display', 3, 800, 4, 0.0, 5, 'EXPANDDETDISP');
        &addrow_details($dispiter, 1, ' Video Memory:', 2, IMachine_getVRAMSize($$gref{IMachine}) . ' MB');
        &addrow_details($dispiter, 1, ' Screens: ', 2, IMachine_getMonitorCount($$gref{IMachine}));
        my $vidaccel = '';
        $vidaccel .= '2D Video  ' if (IMachine_getAccelerate2DVideoEnabled($$gref{IMachine}) eq 'true');
        $vidaccel .= '3D  ' if (IMachine_getAccelerate3DEnabled($$gref{IMachine}) eq 'true');
        $vidaccel ? &addrow_details($dispiter, 1, ' Acceleration:', 2, $vidaccel) : &addrow_details($dispiter, 1, ' Acceleration:', 2, '<None Enabled>');
        IVRDEServer_getEnabled($IVRDEServer) eq 'true' ? &addrow_details($dispiter, 1, ' Remote Display Ports:', 2, IVRDEServer_getVRDEProperty($IVRDEServer, 'TCP/Ports'))
                                                    : &addrow_details($dispiter, 1, ' Remote Display Ports:', 2, '<Remote Display Disabled>');
        $gui{treeviewDetails}->expand_row($treemodel->get_path($dispiter), 1) if ($prefs{EXPANDDETDISP});

        my $storiter = &addrow_details(undef, 0, $gui{img}{CatStor}, 1, 'Storage', 3, 800, 4, 0.0, 5, 'EXPANDDETSTOR');
        foreach my $controller (@IStorageController) {
            my $controllername = IStorageController_getName($controller);
            &addrow_details($storiter, 1, ' Controller:', 2, $controllername);
            my @IMediumAttachment = IMachine_getMediumAttachmentsOfController($$gref{IMachine}, $controllername);
            foreach my $attachment (@IMediumAttachment) {
                if ($$attachment{medium}) {
                    IMedium_refreshState($$attachment{medium}); # Needed to bring in current sizes
                    # Use the base medium for information purposes
                    my $size = &bytesToX(IMedium_getLogicalSize($$attachment{medium}));
                    my $encrypted = &imedium_has_property($$attachment{medium}, 'CRYPT/KeyStore') ? 'Encrypted ' : '';
                    &addrow_details($storiter, 1, "   Port $$attachment{port}:", 2, IMedium_getName(IMedium_getBase($$attachment{medium})) . " ( $$attachment{type} $size $encrypted)");
                }
            }
        }

        $gui{treeviewDetails}->expand_row($treemodel->get_path($storiter), 1) if ($prefs{EXPANDDETSTOR});

        my $audioiter = &addrow_details(undef, 0, $gui{img}{CatAudio}, 1, 'Audio', 3, 800, 4, 0.0, 5, 'EXPANDDETAUDIO');
        IAudioAdapter_getEnabled($IAudioAdapter) eq 'true' ? (&addrow_details($audioiter, 1, ' Host Driver:', 2, IAudioAdapter_getAudioDriver($IAudioAdapter))
                                                        and &addrow_details($audioiter, 1, ' Controller:', 2, IAudioAdapter_getAudioController($IAudioAdapter)))
                                                        : &addrow_details($audioiter, 1, ' <Audio Disabled>');
        $gui{treeviewDetails}->expand_row($treemodel->get_path($audioiter), 1) if ($prefs{EXPANDDETAUDIO});

        my $netiter = &addrow_details(undef, 0, $gui{img}{CatNet}, 1, 'Network', 3, 800, 4, 0.0, 5, 'EXPANDDETNET');
        foreach (0..($$vhost{maxnet}-1)) {
            my $INetworkAdapter = IMachine_getNetworkAdapter($$gref{IMachine}, $_);

            if (INetworkAdapter_getEnabled($INetworkAdapter) eq 'true') {
                my $attachtype = INetworkAdapter_getAttachmentType($INetworkAdapter);
                my $adapter = INetworkAdapter_getAdapterType($INetworkAdapter) . ' (' . $attachtype;

                if ($attachtype eq 'Bridged') { $adapter .= ', ' . INetworkAdapter_getBridgedInterface($INetworkAdapter); }
                elsif ($attachtype eq 'HostOnly') { $adapter .= ', ' . INetworkAdapter_getHostOnlyInterface($INetworkAdapter); }
                elsif ($attachtype eq 'Internal') { $adapter .= ', ' . INetworkAdapter_getInternalNetwork($INetworkAdapter); }

                $adapter .= ')';
                &addrow_details($netiter, 1, " Adapter $_:", 2, $adapter);
            }
        }

        $gui{treeviewDetails}->expand_row($treemodel->get_path($netiter), 1) if ($prefs{EXPANDDETNET});

        my $ioiter = &addrow_details(undef, 0, $gui{img}{CatIO}, 1, 'I/O Ports', 3, 800, 4, 0.0, 5, 'EXPANDDETIO');
        foreach (0..($$vhost{maxser}-1)) {
            my $ISerialPort = IMachine_getSerialPort($$gref{IMachine}, $_);
            ISerialPort_getEnabled($ISerialPort) eq 'true' ? &addrow_details($ioiter, 1, " Serial Port #:" . ($_ + 1), 2, 'Enabled  ' .
                                                                                            ISerialPort_getHostMode($ISerialPort) . '  ' .
                                                                                            ISerialPort_getPath($ISerialPort))
                                                        : &addrow_details($ioiter, 1, " Serial Port #:" . ($_ + 1), 2, 'Disabled');
        }

        my $IParallelPort = IMachine_getParallelPort($$gref{IMachine}, 0);
        IParallelPort_getEnabled($IParallelPort) eq 'true' ? &addrow_details($ioiter, 1, ' LPT Port:', 2, 'Enabled  ' . IParallelPort_getPath($IParallelPort))
                                                        : &addrow_details($ioiter, 1, ' LPT Port:', 2, 'Disabled');
        $gui{treeviewDetails}->expand_row($treemodel->get_path($ioiter), 1) if ($prefs{EXPANDDETIO});

        my $usbiter = &addrow_details(undef, 0, $gui{img}{CatUSB}, 1, 'USB', 3, 800, 4, 0.0, 5, 'EXPANDDETUSB');
        if (@IUSBController) {
            foreach my $usbcontroller (@IUSBController) {
                my $usbver = IUSBController_getUSBStandard($usbcontroller);
                &addrow_details($usbiter, 1, ' Controller:',
                                        2, IUSBController_getName($usbcontroller) .
                                        ' (' . IUSBController_getType($usbcontroller) . ')');
            }

            my $IUSBDeviceFilters = IMachine_getUSBDeviceFilters($$gref{IMachine});
            my @filters = IUSBDeviceFilters_getDeviceFilters($IUSBDeviceFilters);
            my $active = 0;
            foreach (@filters) { $active++ if (IUSBDeviceFilter_getActive($_) eq 'true'); }
            &addrow_details($usbiter, 1, '  Device Filters:', 2,  scalar(@filters) . " ($active active)");
        }
        else { &addrow_details($usbiter, 1, ' <None Enabled>'); }
        $gui{treeviewDetails}->expand_row($treemodel->get_path($usbiter), 1) if ($prefs{EXPANDDETUSB});

        my $shareiter = &addrow_details(undef, 0, $gui{img}{CatShare}, 1, 'Shared Folders', 3, 800, 4, 0.0, 5, 'EXPANDDETSHARE');
        my @sf = IMachine_getSharedFolders($$gref{IMachine});
        &addrow_details($shareiter, 1, ' Shared Folders:', 2, scalar(@sf));
        $gui{treeviewDetails}->expand_row($treemodel->get_path($shareiter), 1) if ($prefs{EXPANDDETSHARE});

        my $sref = &get_session($$gref{IMachine});

        if ($$sref{Lock} eq 'Shared') {
            my $runiter = &addrow_details(undef, 0, $gui{img}{CatGen}, 1, 'Runtime Details', 3, 800, 4, 0.0, 5, 'EXPANDDETRUN');
            my $IGuest = IConsole_getGuest(ISession_getConsole($$sref{ISession}));
            &addrow_details($runiter, 1, ' OS:', 2, IGuest_getOSTypeId($IGuest));
            my $additionsversion = IGuest_getAdditionsVersion($IGuest);
            if ($additionsversion) { &addrow_details($runiter, 1, ' Guest Additions:', 2, $additionsversion); }
            else { &addrow_details($runiter, 1, ' Guest Additions:', 2, 'Not Installed (or not running)'); }
            $gui{treeviewDetails}->expand_row($treemodel->get_path($runiter), 1) if ($prefs{EXPANDDETRUN});
        }

        ISession_unlockMachine($$sref{ISession}) if (ISession_getState($$sref{ISession}) eq 'Locked');

        my $desciter = &addrow_details(undef, 0, $gui{img}{CatDesc}, 1, 'Description', 3, 800, 4, 0.0, 5, 'EXPANDDETDESC');
        my $desc = IMachine_getDescription($$gref{IMachine});
        $desc ? &addrow_details($desciter, 1, ' Description:', 2, $desc)
            : &addrow_details($desciter, 1, ' <None>');
        $gui{treeviewDetails}->expand_row($treemodel->get_path($desciter), 1) if ($prefs{EXPANDDETDESC});

        &addrow_log("Extended guest details retrieved.");
    }
}

# Adds a line to the details view
sub addrow_details {
    my $iter = shift;
    my $citer = $gui{treestoreDetails}->append($iter);
    $gui{treestoreDetails}->set($citer, @_);
    return $citer;
}

# Fills the remote file chooser with a list of files. Involves a lot of splicing because
# of the crazy way VirtualBox returns a file list
sub fill_list_remotefiles {
    &busy_pointer($gui{dialogRemoteFileChooser}, 1);
    my ($location, $filter) = @_;
    my $vhost = &vhost();
    $location = &rcanonpath($location);
    my $IProgress = IVFSExplorer_cd($gui{IVFSExplorer}, $location);
    IProgress_waitForCompletion($IProgress);

    if (&bl(IProgress_getCompleted($IProgress)) and (IProgress_getResultCode($IProgress) == 0)) { # Only update the view if the CD is successful.
        $gui{liststoreRemoteFileChooser}->clear();
        IVFSExplorer_update($gui{IVFSExplorer});
        my @entries = IVFSExplorer_entryList($gui{IVFSExplorer});
        my $chop = (@entries / 4);
        my @filenames = splice @entries, 0, $chop;
        my @types = splice @entries, 0, $chop;
        my @sizes = splice @entries, 0, $chop;
        my @modes = splice @entries, 0, $chop;
        my %files;

        foreach my $ent (0..$#filenames) {
            $files{$filenames[$ent]}{type} = $types[$ent];
            $files{$filenames[$ent]}{size} = $sizes[$ent];
            $files{$filenames[$ent]}{mode} = sprintf "%o", $modes[$ent];
        }

        my $iter = $gui{liststoreRemoteFileChooser}->append();
        $gui{liststoreRemoteFileChooser}->set($iter, 0, '(Parent)', 1, '..', 2, '', 3, '', 4, $gui{img}{ParentIcon});

        foreach my $fname (sort { lc($a) cmp lc($b) } (keys %files)) {

            if ($files{$fname}{type} == 4) { # Always add in directories
                my $iter = $gui{liststoreRemoteFileChooser}->append();
                $gui{liststoreRemoteFileChooser}->set($iter, 0, '(Dir)', 1, $fname, 2, $files{$fname}{size}, 3, $files{$fname}{mode}, 4, $gui{img}{DirIcon});
            }
            elsif ($fname =~ m/$filter/i) { # Only add in if it matches the filter
                my $iter = $gui{liststoreRemoteFileChooser}->append();
                $fname =~ m/^.*\.(.*)$/;
                my $ext = $1 ? lc(".$1") : ' ';
                $gui{liststoreRemoteFileChooser}->set($iter, 0, $ext, 1, $fname, 2, $files{$fname}{size}, 3, $files{$fname}{mode}, 4, $gui{img}{FileIcon});
            }
        }

        $gui{entryRemoteFileChooserLocation}->set_text(IVFSExplorer_getPath($gui{IVFSExplorer}));
    }
    else {
        IVFSExplorer_cdUp($gui{IVFSExplorer}); # Failed to CD, so the path needs to be set back to the previous one
        $gui{entryRemoteFileChooserLocation}->set_text(IVFSExplorer_getPath($gui{IVFSExplorer}));
        show_err_msg('nodiraccess', '');
    }

    &busy_pointer($gui{dialogRemoteFileChooser}, 0);
}

# Fills a list as returned from reading the remote log file
sub fill_list_log {
    my ($IMachine) = @_;
    $gui{liststoreLog0}->clear();
    $gui{liststoreLog1}->clear();
    $gui{liststoreLog2}->clear();
    $gui{liststoreLog3}->clear();

    for my $lognum (0..3) {
        my $log;
        my $offset = 0;

        if (IMachine_queryLogFilename($IMachine, $lognum)) {
            # Reading logs is limited to a maximum chunk size - normally 32K. The chunks are base64 encoded so we
            # need to read a chunk, decode, calculate next offset. Limit loop to 40 runs (max 1MB retrieval)
            for (1..40) {
                my $rawlog = IMachine_readLog($IMachine, $lognum, $offset, 32768); # Request 32K max. Limit is usually 32K anyway
                last if (!$rawlog); # Terminate loop if we've reached the end or log is empty
                $log .= decode_base64($rawlog); # Rawlog is base64 encoded. Append to log
                $offset = length($log); # Set next offset into log to get the next chunk
            }

            if ($log) {
                my @logarr = split "\n", $log; # Do we need to include windows/mac EOL here?

                foreach (0..$#logarr) {
                    $logarr[$_] =~ s/\r//g;
                    my $iter = $gui{'liststoreLog' . $lognum}->append;
                    $gui{'liststoreLog' . $lognum}->set($iter, 0, "$_: ", 1, $logarr[$_]);
                }
            }
            else {
                my $iter = $gui{'liststoreLog' . $lognum}->append;
                $gui{'liststoreLog' . $lognum}->set($iter, 0, '', 1, 'This log file is currently empty');
            }

        }
        else {
            my $iter = $gui{'liststoreLog' . $lognum}->append;
            $gui{'liststoreLog' . $lognum}->set($iter, 0, '', 1, 'This log file does not yet exist.');
        }
    }
}

# Fills a list of basic information about the remote server
sub fill_list_serverinfo {
    $gui{liststoreInfo}->clear();
    my $vhost = &vhost();
    &addrow_info(0, 'URL:', 1, $endpoint);
    &addrow_info(0, 'VirtualBox Version:', 1, $$vhost{vbver});
    $$vhost{vrdeextpack} ? &addrow_info(0, 'Extension Pack:', 1, $$vhost{vrdeextpack}) : &addrow_info(0, 'Extension Pack:', 1, '<None>');
    &addrow_info(0, 'Build Revision:', 1, $$vhost{buildrev});
    &addrow_info(0, 'Package Type:', 1, $$vhost{pkgtype});
    &addrow_info(0, 'Global Settings File:', 1, $$vhost{settingsfile});
    &addrow_info(0, 'Machine Folder:', 1, $$vhost{machinedir});
    &addrow_info(0, 'Server Logical CPUs:', 1, $$vhost{maxhostcpuon});
    &addrow_info(0, 'Server CPU Type:', 1, $$vhost{cpudesc});
    &addrow_info(0, 'Server CPU Speed:', 1, "$$vhost{cpuspeed} Mhz (approx)");
    &addrow_info(0, 'VT-x/AMD-V Support:', 1, "$$vhost{vtx}");
    &addrow_info(0, 'VT-x/AMD-V Exclusive:', 1, $$vhost{hwexclusive});
    &addrow_info(0, 'PAE Support:', 1, "$$vhost{pae}");
    &addrow_info(0, 'Server Memory Size:', 1, "$$vhost{memsize} MB");
    &addrow_info(0, 'Server OS:', 1, $$vhost{os});
    &addrow_info(0, 'Server OS Version:', 1, $$vhost{osver});
    &addrow_info(0, 'Default Audio:', 1, $$vhost{defaudio});
    &addrow_info(0, 'Min Guest RAM:', 1, "$$vhost{minguestram} MB");
    &addrow_info(0, 'Max Guest RAM:', 1, &bytesToX($$vhost{maxguestram} * 1048576));
    &addrow_info(0, 'Min Guest Video RAM:', 1, "$$vhost{minguestvram} MB");
    &addrow_info(0, 'Max Guest Video RAM:', 1, "$$vhost{maxguestvram} MB");
    &addrow_info(0, 'Max Guest CPUs:', 1, $$vhost{maxguestcpu});
    &addrow_info(0, 'Max Guest Monitors:', 1, $$vhost{maxmonitors});
    &addrow_info(0, 'Max HD Image Size:', 1, &bytesToX($$vhost{maxhdsize}));
    &addrow_info(0, 'Guest Additions ISO:', 1, $$vhost{additionsiso});
    &addrow_info(0, 'Autostart DB:', 1, $$vhost{autostartdb});
}

# Populate the permanent and transient shared folder list for the guest settings
sub fill_list_editshared {
    my ($IMachine) = @_;
    my $sref = &get_session($IMachine);
    my @ISharedFolderPerm = IMachine_getSharedFolders($IMachine);
    my $IConsole = ISession_getConsole($$sref{ISession});
    my @ISharedFolderTran = IConsole_getSharedFolders($IConsole) if ($IConsole);
    $gui{buttonEditSharedRemove}->set_sensitive(0);
    $gui{buttonEditSharedEdit}->set_sensitive(0);
    $gui{liststoreEditShared}->clear();

    foreach (@ISharedFolderPerm) { &addrow_editshared($_, 'Yes'); }
    foreach (@ISharedFolderTran) { &addrow_editshared($_, 'No'); }
}

# Populates the guest's storage list
sub fill_list_editstorage {
    my ($IMachine) = @_;
    &busy_pointer($gui{dialogEdit}, 1);
    &storage_sens_nosel();
    $gui{treestoreEditStor}->clear();
    my @IStorageController = IMachine_getStorageControllers($IMachine);

    foreach my $controller (@IStorageController) {
        Gtk2->main_iteration() while Gtk2->events_pending();
        my %ctr_attr = (name  => 1,
                        bus   => 1);
        &get_icontroller_attrs(\%ctr_attr, $controller); # Fill hash with attributes
        my $iter = $gui{treestoreEditStor}->append(undef);

        $gui{treestoreEditStor}->set($iter, 0,  $ctr_attr{name},                 # Display Name
                                            1,  $ctr_attr{bus} . ' Controller',  # Display Type
                                            2,  $ctr_attr{bus} . ' Controller',  # Tooltip
                                            3,  1,                               # Is it a controller
                                            4,  $ctr_attr{bus},                  # Controller BUS
                                            5,  $ctr_attr{name},                 # Controller's Name
                                            7,  $controller,                     # IStorageController object
                                            12, $gui{img}{ctr}{$ctr_attr{bus}});

        my @IMediumAttachment = IMachine_getMediumAttachmentsOfController($IMachine, $ctr_attr{name});

        foreach my $attach (@IMediumAttachment) {
            my $citer = $gui{treestoreEditStor}->append($iter);
            my %medium_attr = (refresh  => 1,
                               size     => 1,
                               logsize  => 1,
                               location => 1);
            &get_imedium_attrs(\%medium_attr, $$attach{medium});

            if ($$attach{medium}) { # Is it a medium or empty drive
                my $baseIMedium = IMedium_getBase($$attach{medium});
                my $mediumname = ($$attach{medium} eq $baseIMedium) ? IMedium_getName($baseIMedium) : "(*) " . IMedium_getName($baseIMedium); #Tests for snapshots
                $mediumname = '<Server Drive> ' . $medium_attr{location} if (&bl(IMedium_getHostDrive($$attach{medium})));
                $gui{treestoreEditStor}->set($citer, 0,  $mediumname,                            # Display Name
                                                     1,  $$attach{type},                         # Display Type
                                                     2,  "$medium_attr{location}\nPhysical Size: " .
                                                         &bytesToX($medium_attr{size}) . "\nLogical Size: " .
                                                         &bytesToX($medium_attr{logsize}),       # ToolTip
                                                     3,  0,                                      # Is it a controller
                                                     4,  $ctr_attr{bus},                         # The bus the medium is on
                                                     5,  $ctr_attr{name},                        # The name of the controller it is on
                                                     6,  $$attach{medium},                       # IMedium Object
                                                     7,  $controller,                            # IStorageController it is on
                                                     8,  $$attach{type},                         # Medium Type
                                                     9,  $$attach{device},                       # Device number
                                                     10, $$attach{port},                         # Port Number
                                                     11, $medium_attr{location},                 # Location
                                                     12, $gui{img}{$$attach{type}});

            }
            else {
                $gui{treestoreEditStor}->set($citer, 0,  '<Empty Drive>',               # Display Name
                                                     1,  $$attach{type},                # Display Typee
                                                     2,  "Empty Drive",  # Tooltip
                                                     3,  0,                             # Is it a controller
                                                     4,  $ctr_attr{bus},                # The bus the medium is on
                                                     5,  $ctr_attr{name},               # The name of the controller it is on
                                                     7,  $controller,                   # IStorageController it is on
                                                     8,  $$attach{type},                # Medium Type
                                                     9,  $$attach{device},              # Device number
                                                     10, $$attach{port},                # Port Number
                                                     12, $gui{img}{$$attach{type}});
            }
        }
    }

    $gui{treeviewEditStor}->expand_all();
    &busy_pointer($gui{dialogEdit}, 0);
}

# VBPrefs NAT List Handling
{
    my %selected = (INATNetwork => '');

    sub getsel_list_vbprefsnat { return \%selected; }

    sub fill_list_vbprefsnat {
        &busy_pointer($gui{dialogVBPrefs}, 1);
        $gui{buttonVBPrefsDelNAT}->set_sensitive(0);
        $gui{buttonVBPrefsEditNAT}->set_sensitive(0);
        $gui{liststoreVBPrefsNAT}->clear();
        my @INATNetwork = IVirtualBox_getNATNetworks($gui{websn});

        foreach my $nat (@INATNetwork) {
            my $iter = $gui{liststoreVBPrefsNAT}->append();
            $gui{liststoreVBPrefsNAT}->set($iter, 0, &bl(INATNetwork_getEnabled($nat)),
                                                  1, INATNetwork_getNetworkName($nat),
                                                  2, $nat);

            if ($nat eq $selected{INATNetwork}) {
                $gui{treeviewVBPrefsNAT}->get_selection()->select_iter($iter);
                &onsel_list_vbprefsnat();
            }
        }

        &busy_pointer($gui{dialogVBPrefs}, 0);
    }

    sub onsel_list_vbprefsnat {
        my $model = $gui{treeviewVBPrefsNAT}->get_model();
        my $iter = $gui{treeviewVBPrefsNAT}->get_selection->get_selected() ? $gui{treeviewVBPrefsNAT}->get_selection->get_selected() : $model->get_iter_first();
        my @row = $model->get($iter);
        $selected{$_} = shift @row foreach('Enabled', 'Name', 'INATNetwork');
        $gui{buttonVBPrefsDelNAT}->set_sensitive(1);
        $gui{buttonVBPrefsEditNAT}->set_sensitive(1);
    }
}

# VBPrefs HON List Handling
{
    my %selected = (Uuid => '');

    sub getsel_list_vbprefshon { return \%selected; }

    sub fill_list_vbprefshon {
        &busy_pointer($gui{dialogVBPrefs}, 1);
        $gui{buttonVBPrefsDelHON}->set_sensitive(0);
        $gui{buttonVBPrefsEditHON}->set_sensitive(0);
        $gui{liststoreVBPrefsHON}->clear();
        my $IHost = IVirtualBox_getHost($gui{websn});
        my @IHostNetworkInterface = IHost_findHostNetworkInterfacesOfType($IHost, 'HostOnly');

        foreach my $if (@IHostNetworkInterface) {
            my $iter = $gui{liststoreVBPrefsHON}->append();
            my $uuid = IHostNetworkInterface_getId($if);
            $gui{liststoreVBPrefsHON}->set($iter, 0, IHostNetworkInterface_getName($if),
                                                  1, $if,
                                                  2, $uuid);

            if ($uuid eq $selected{Uuid}) {
                $gui{treeviewVBPrefsHON}->get_selection()->select_iter($iter);
                &onsel_list_vbprefshon();
            }
        }

        &busy_pointer($gui{dialogVBPrefs}, 0);
    }

    sub onsel_list_vbprefshon {
        my $model = $gui{treeviewVBPrefsHON}->get_model();
        my $iter =  $gui{treeviewVBPrefsHON}->get_selection->get_selected() ? $gui{treeviewVBPrefsHON}->get_selection->get_selected() : $model->get_iter_first();
        my @row = $model->get($iter);
        $selected{$_} = shift @row foreach ('Name', 'IHostNetworkInterface', 'Uuid');
        $gui{buttonVBPrefsDelHON}->set_sensitive(1);
        $gui{buttonVBPrefsEditHON}->set_sensitive(1);
    }
}

# Adds a message to message log and scrolls to bottom
sub addrow_log {
    my ($msg) = @_;
    my $iter = $gui{liststoreLog}->append;
    my ($sec,$min,$hour,$mday,$mon,$year) = localtime();
    $mon += 1;
    $year += 1900;
    $msg = sprintf("%d-%02d-%02d %02d:%02d:%02d    %s", $year, $mon, $mday, $hour, $min, $sec, $msg);
    $gui{liststoreLog}->set($iter, 0, $msg);
    $gui{treeviewLog}->scroll_to_cell($gui{treeviewLog}->get_model->get_path($iter));
}

# Adds a row to the editshared list
sub addrow_editshared {
    my ($ISharedFolder, $permanent) = @_;
    my $shrname = ISharedFolder_getName($ISharedFolder);
    my $shrpath = ISharedFolder_getHostPath($ISharedFolder);
    my $shrerror = ISharedFolder_getLastAccessError($ISharedFolder);
    my $shraccessible = ISharedFolder_getAccessible($ISharedFolder);
    my $access = 'Full';
    my $automount = 'No';
    my $tooltip = ($shrerror) ? $shrerror : "$shrname ($shrpath)";
    $tooltip .= ($shraccessible eq 'false') ? ' : Share is not accessible' : '';
    $access = 'Read-Only' if (ISharedFolder_getWritable($ISharedFolder) eq 'false');
    $automount = 'Yes' if (ISharedFolder_getAutoMount($ISharedFolder) eq 'true');
    my $iter = $gui{liststoreEditShared}->append;
    if ($shraccessible eq 'false') { $gui{liststoreEditShared}->set($iter, 0, $shrname, 1, $shrpath, 2, $access, 3, $automount, 4, $gui{img}{Error}, 5, $tooltip, 6, $permanent); }
    else { $gui{liststoreEditShared}->set($iter, 0, $shrname, 1, $shrpath, 2, $access, 3, $automount, 5, $tooltip, 6, $permanent); }
}

sub addrow_info {
    my $iter = $gui{liststoreInfo}->append;
    $gui{liststoreInfo}->set($iter, @_);
    return $iter;
}

sub addrow_ec {
    my $iter = $gui{liststoreEvalConfig}->append;
    $gui{liststoreEvalConfig}->set($iter, @_);
    return $iter;
}

# Returns the contents of the chosen column of the selected combobox row or
# returns the row iterator if no column is chosen
sub getsel_combo {
    my ($widget, $col) = @_;
    my $model = $widget->get_model();
    my $iter = $widget->get_active_iter();

    if (defined($col)) { return $model->get($iter, $col); }
    else { return $model->get($iter); }
}

# Sets the combobox active to the chosen text in the chosen column
sub combobox_set_active_text {
    my ($combobox, $txt, $col) = @_;
    my $i = 0;
    $combobox->get_model->foreach (
                            sub {
                                my ($model, $path, $iter) = @_;
                                if ($txt eq $model->get_value($iter, $col)) {
                                    ($i) = $path->get_indices;
                                    return 1; # stop
                                }
                                return 0; # continue
                            }
                          );
    $combobox->set_active($i);
}

# Handles single and multiple selections
sub getsel_list_remotefiles {
    my @filearray;
    my $model = $gui{treeviewRemoteFileChooser}->get_model();
    my @selections = $gui{treeviewRemoteFileChooser}->get_selection->get_selected_rows();

    foreach my $select (@selections) {
        my $iter = $model->get_iter($select);
        next if (!$iter);
        my @row = $model->get($iter);

        push @filearray, {Type     => $row[0],
                          FileName => $row[1],
                          Size     => $row[2],
                          Mode     => $row[3]};
    }

    return \@filearray;
}

sub getsel_list_editshared {
    my $model = $gui{treeviewEditShared}->get_model();
    my ($path) = $gui{treeviewEditShared}->get_cursor();
    my $iter = $gui{treeviewEditShared}->get_selection->get_selected() ? $model->get_iter($path) : $model->get_iter_first();
    return undef if (!$iter);
    my @row = $model->get($iter);
    my %hash;
    $hash{$_} = shift @row foreach ('Name', 'Folder', 'Access', 'Mount', 'Accessible', 'Tooltip', 'Permanent');
    return \%hash;
}

sub getsel_list_editstorage {
    my $model = $gui{treeviewEditStor}->get_model();
    my ($path) = $gui{treeviewEditStor}->get_cursor();
    my $iter = $gui{treeviewEditStor}->get_selection->get_selected() ? $model->get_iter($path) : $model->get_iter_first();
    return undef if (!$iter);
    my @row = $model->get($iter);
    my %hash;
    $hash{$_} = shift @row foreach ('DisplayName', 'DisplayType', 'Tooltip', 'IsController', 'Bus', 'ControllerName', 'IMedium', 'IStorageController', 'MediumType', 'Device', 'Port', 'Location', 'Icon');
    return \%hash;
}

# USB Filter List Handling
{
    my %selected = (IUSBDeviceFilter => '');

    sub getsel_list_usbfilters { return \%selected; }

    sub onsel_list_usbfilters {
        my $model = $gui{treeviewEditUSBFilters}->get_model();
        my $iter = $gui{treeviewEditUSBFilters}->get_selection->get_selected() ? $gui{treeviewEditUSBFilters}->get_selection->get_selected() : $model->get_iter_first();
        my @row = $model->get($iter);
        $selected{$_} = shift @row foreach ('Enabled', 'IUSBDeviceFilter', 'Name', 'Position');
        $gui{buttonEditUSBEdit}->set_sensitive(1);
        $gui{buttonEditUSBRemove}->set_sensitive(1);
        $gui{buttonEditUSBUp}->set_sensitive(1);
        $gui{buttonEditUSBDown}->set_sensitive(1);
    }

    sub fill_list_usbfilters {
        &busy_pointer($gui{dialogEdit}, 1);
        my ($IMachine) = @_;
        $gui{buttonEditUSBEdit}->set_sensitive(0);
        $gui{buttonEditUSBRemove}->set_sensitive(0);
        $gui{buttonEditUSBUp}->set_sensitive(0);
        $gui{buttonEditUSBDown}->set_sensitive(0);
        $gui{liststoreEditUSBFilter}->clear();
        my $IUSBDeviceFilters = IMachine_getUSBDeviceFilters($IMachine);
        my @filters = IUSBDeviceFilters_getDeviceFilters($IUSBDeviceFilters);
        my $pos = 0;

        foreach my $filter (@filters) {
            my $iter = $gui{liststoreEditUSBFilter}->append();
            $gui{liststoreEditUSBFilter}->set($iter,
                                        0, &bl(IUSBDeviceFilter_getActive($filter)),
                                        1, $filter,
                                        2, IUSBDeviceFilter_getName($filter),
                                        3, $pos);

            if ($filter eq $selected{IUSBDeviceFilter}) {
                $gui{treeviewEditUSBFilters}->get_selection()->select_iter($iter);
                &onsel_list_usbfilters();
            }

            $pos++;
        }
        &busy_pointer($gui{dialogEdit}, 0);
    }
}

sub onsel_list_remotefiles {
    my $filearrayref = &getsel_list_remotefiles();

    # We only care about the first file selected, and only if it's a directory
    my $fileref = ${$filearrayref}[0];

    if ($$fileref{FileName} eq '..') { &cdup_remotefilechooser(); }
    elsif ($$fileref{Type} eq '(Dir)') {
        my $path = IVFSExplorer_getPath($gui{IVFSExplorer});
        IVFSExplorer_cd($gui{IVFSExplorer}, &rcatdir($path, $$fileref{FileName}));
        &fill_list_remotefiles(IVFSExplorer_getPath($gui{IVFSExplorer}), $gui{entryRemoteFileChooserFilter}->get_text());
    }
}

sub onsel_list_remotefiles_single {
    my $filearrayref = &getsel_list_remotefiles();

    # We only care about the first file selected, and only if it's a file
    my $fileref = ${$filearrayref}[0];
    if ($$fileref{FileName} ne '..' and $$fileref{Type} ne '(Dir)') { $gui{entryRemoteFileChooserFile}->set_text($$fileref{FileName}); }
}

# Activates when selecting an item in the edit storage list, could be reduced a little
# as a lot of the options are the same for each controller but this gives flexibility
# to expand
sub onsel_list_editstorage {
    my $storref = &getsel_list_editstorage();
    # Sensitivities for all selections
    $gui{frameEditStorAttr}->show();
    $gui{buttonEditStorAddAttach}->set_sensitive(1);
    $gui{checkbuttonEditStorHotPluggable}->hide();
    $gui{checkbuttonEditStorSSD}->hide();
    $gui{spinbuttonEditStorPortCount}->hide();
    $gui{checkbuttonEditStorControllerBootable}->hide();

    if ($$storref{IsController}) {
        # Sensitivities for all controllers
        $gui{buttonEditStorRemoveAttach}->set_sensitive(0);
        $gui{buttonEditStorRemoveCtr}->set_sensitive(1);
        $gui{labelEditStorCtrName}->show();
        $gui{entryEditStorCtrName}->show();
        $gui{labelEditStorCtrType}->show();
        $gui{comboboxEditStorCtrType}->show();
        $gui{checkbuttonEditStorCache}->show();
        $gui{labelEditStorDevPort}->hide();
        $gui{comboboxEditStorDevPort}->hide();
        $gui{checkbuttonEditStorLive}->hide();
        $gui{checkbuttonEditStorControllerBootable}->show();
        $gui{labelEditStorPortCount}->hide();
        $gui{labelEditStorFloppyType}->hide();
        $gui{comboboxEditStorFloppyType}->hide();
        $gui{menuitemAttachHD}->set_sensitive(1);
        $gui{menuitemAttachDVD}->set_sensitive(1);
        $gui{menuitemAttachFloppy}->set_sensitive(0);
        $gui{comboboxEditStorCtrType}->signal_handler_block($signal{stortype});
        $gui{entryEditStorCtrName}->set_text($$storref{ControllerName});
        $gui{checkbuttonEditStorCache}->set_active(&bl(IStorageController_getUseHostIOCache($$storref{IStorageController})));
        $gui{checkbuttonEditStorControllerBootable}->set_active(&bl(IStorageController_getBootable($$storref{IStorageController})));

        my $variant = IStorageController_getControllerType($$storref{IStorageController});

        if ($$storref{Bus} eq 'IDE') { $gui{comboboxEditStorCtrType}->set_model($gui{liststoreEditStorIDECtrType}); }
        elsif ($$storref{Bus} eq 'USB') { $gui{comboboxEditStorCtrType}->set_model($gui{liststoreEditStorUSBCtrType}); }
        elsif ($$storref{Bus} eq 'SCSI') { $gui{comboboxEditStorCtrType}->set_model($gui{liststoreEditStorSCSICtrType}); }
        elsif ($$storref{Bus} eq 'SATA') {
            $gui{labelEditStorPortCount}->show();
            $gui{spinbuttonEditStorPortCount}->show();
            $gui{menuitemAttachFloppy}->set_sensitive(0);
            $gui{comboboxEditStorCtrType}->set_model($gui{liststoreEditStorSATACtrType});
            $gui{spinbuttonEditStorPortCount}->set_range(1, 30);
            $gui{adjustmentEditStorPortCount}->set_value(IStorageController_getPortCount($$storref{IStorageController}));
        }
        elsif ($$storref{Bus} eq 'SAS') {
            $gui{labelEditStorPortCount}->show();
            $gui{spinbuttonEditStorPortCount}->show();
            $gui{menuitemAttachFloppy}->set_sensitive(0);
            $gui{comboboxEditStorCtrType}->set_model($gui{liststoreEditStorSASCtrType});
            $gui{spinbuttonEditStorPortCount}->set_range(1, 254);
            $gui{adjustmentEditStorPortCount}->set_value(IStorageController_getPortCount($$storref{IStorageController}));
        }
        elsif ($$storref{Bus} eq 'PCIe') {
            $gui{labelEditStorPortCount}->show();
            $gui{spinbuttonEditStorPortCount}->show();
            $gui{menuitemAttachDVD}->set_sensitive(0);
            $gui{menuitemAttachFloppy}->set_sensitive(0);
            $gui{comboboxEditStorCtrType}->set_model($gui{liststoreEditStorNVMeCtrType});
            $gui{spinbuttonEditStorPortCount}->set_range(1, 254);
            $gui{adjustmentEditStorPortCount}->set_value(IStorageController_getPortCount($$storref{IStorageController}));
        }
        else { # Default is floppy
            $gui{menuitemAttachHD}->set_sensitive(0);
            $gui{menuitemAttachDVD}->set_sensitive(0);
            $gui{menuitemAttachFloppy}->set_sensitive(1);
            $gui{comboboxEditStorCtrType}->set_model($gui{liststoreEditStorFloppyCtrType});
        }

        &combobox_set_active_text($gui{comboboxEditStorCtrType}, $variant, 0);
        $gui{comboboxEditStorCtrType}->signal_handler_unblock($signal{stortype});
    }
    else { # This is a medium, not a controller
        $gui{buttonEditStorRemoveAttach}->set_sensitive(1);
        $gui{buttonEditStorRemoveCtr}->set_sensitive(0);
        $gui{labelEditStorCtrName}->hide();
        $gui{entryEditStorCtrName}->hide();
        $gui{labelEditStorCtrType}->hide();
        $gui{comboboxEditStorCtrType}->hide();
        $gui{checkbuttonEditStorCache}->hide();
        $gui{checkbuttonEditStorLive}->hide();
        $gui{labelEditStorDevPort}->show();
        $gui{comboboxEditStorDevPort}->show();
        $gui{labelEditStorPortCount}->hide();
        $gui{labelEditStorFloppyType}->hide();
        $gui{comboboxEditStorFloppyType}->hide();
        $gui{menuitemAttachHD}->set_sensitive(0);
        $gui{menuitemAttachDVD}->set_sensitive(0);
        $gui{menuitemAttachFloppy}->set_sensitive(0);

        if ($$storref{MediumType} eq 'DVD') {
            my $attach = IMachine_getMediumAttachment($vmc{IMachine}, $$storref{ControllerName}, $$storref{Port}, $$storref{Device});
            $gui{checkbuttonEditStorLive}->show();
            $gui{checkbuttonEditStorLive}->set_active(&bl($$attach{temporaryEject}));
            $gui{menuitemAttachDVD}->set_sensitive(1);
            # Only SATA & USB controllers support hot pluggable
            if ($$storref{Bus} eq 'SATA' or $$storref{Bus} eq 'USB') {
                $gui{checkbuttonEditStorHotPluggable}->set_active(&bl($$attach{hotPluggable}));
                $gui{checkbuttonEditStorHotPluggable}->show();
            }
            else { $gui{checkbuttonEditStorHotPluggable}->hide(); }
        }
        elsif ($$storref{MediumType} eq 'Floppy') {
            $gui{labelEditStorFloppyType}->show();
            $gui{comboboxEditStorFloppyType}->show();
            my $fdrivetype = IMachine_getExtraData($vmc{IMachine}, 'VBoxInternal/Devices/i82078/0/LUN#' . $$storref{Device} . '/Config/Type');
            if ($fdrivetype eq 'Floppy 360') { $gui{comboboxEditStorFloppyType}->set_active(0); }
            elsif ($fdrivetype eq 'Floppy 720') { $gui{comboboxEditStorFloppyType}->set_active(1); }
            elsif ($fdrivetype eq 'Floppy 1.20') { $gui{comboboxEditStorFloppyType}->set_active(2); }
            elsif ($fdrivetype eq 'Floppy 2.88') { $gui{comboboxEditStorFloppyType}->set_active(4); }
            elsif ($fdrivetype eq 'Floppy 15.6') { $gui{comboboxEditStorFloppyType}->set_active(5); }
            elsif ($fdrivetype eq 'Floppy 63.5') { $gui{comboboxEditStorFloppyType}->set_active(6); }
            else { $gui{comboboxEditStorFloppyType}->set_active(3); } # Everything else is 1.44MB
            $gui{menuitemAttachFloppy}->set_sensitive(1);
        }
        else { # Default to HD
            my $attach = IMachine_getMediumAttachment($vmc{IMachine}, $$storref{ControllerName}, $$storref{Port}, $$storref{Device});
            $gui{checkbuttonEditStorSSD}->set_active(&bl($$attach{nonRotational}));
            $gui{buttonEditStorAddAttach}->set_sensitive(0);
            $gui{checkbuttonEditStorSSD}->show();
            # Only SATA & USB controllers support hot pluggable
            if ($$storref{Bus} eq 'SATA' or $$storref{Bus} eq 'USB') {
                $gui{checkbuttonEditStorHotPluggable}->set_active(&bl($$attach{hotPluggable}));
                $gui{checkbuttonEditStorHotPluggable}->show();
            }
            else { $gui{checkbuttonEditStorHotPluggable}->hide(); }
        }

        # We also need to setup the port comboboxEditStorDevPort
        if ($$storref{Bus} eq 'SATA') {
            $gui{comboboxEditStorDevPort}->set_model($gui{liststoreEditStorDevPortSATA});
            $gui{comboboxEditStorDevPort}->set_active($$storref{Port});
        }
        elsif ($$storref{Bus} eq 'IDE') {
            $gui{comboboxEditStorDevPort}->set_model($gui{liststoreEditStorDevPortIDE});
            if ($$storref{Device} == 0 and $$storref{Port} == 0) { $gui{comboboxEditStorDevPort}->set_active(0); }
            elsif ($$storref{Device} == 1 and $$storref{Port} == 0) { $gui{comboboxEditStorDevPort}->set_active(1); }
            elsif ($$storref{Device} == 0 and $$storref{Port} == 1) { $gui{comboboxEditStorDevPort}->set_active(2); }
            elsif ($$storref{Device} == 1 and $$storref{Port} == 1) { $gui{comboboxEditStorDevPort}->set_active(3); }
        }
        elsif ($$storref{Bus} eq 'SAS') {
            $gui{comboboxEditStorDevPort}->set_model($gui{liststoreEditStorDevPortSAS});
            $gui{comboboxEditStorDevPort}->set_active($$storref{Port});
        }
        elsif ($$storref{Bus} eq 'SCSI') {
            $gui{comboboxEditStorDevPort}->set_model($gui{liststoreEditStorDevPortSCSI});
            $gui{comboboxEditStorDevPort}->set_active($$storref{Port});
        }
        elsif ($$storref{Bus} eq 'Floppy') {
            $gui{comboboxEditStorDevPort}->set_model($gui{liststoreEditStorDevPortFloppy});
            $gui{comboboxEditStorDevPort}->set_active($$storref{Device});
        }
        elsif ($$storref{Bus} eq 'PCIe') {
            $gui{comboboxEditStorDevPort}->set_model($gui{liststoreEditStorDevPortNVMe});
            $gui{comboboxEditStorDevPort}->set_active($$storref{Port});
        }
        elsif ($$storref{Bus} eq 'USB') {
            $gui{comboboxEditStorDevPort}->set_model($gui{liststoreEditStorDevPortUSB});
            $gui{comboboxEditStorDevPort}->set_active($$storref{Port});
        }
    }
}

# VMM Floppy List Handling
{
    my %selected = (IMedium => '');

    # Return the selected entry in the VMM floppy disk list
    sub getsel_list_vmmfloppy { return \%selected; }

    # Fill the floppy media list in the VMM
    sub fill_list_vmmfloppy {
        &busy_pointer($gui{dialogVMM}, 1);
        &clr_list_vmm($gui{treestoreVMMFloppy});
        my $IMediumRef = &get_all_media('Floppy');

        foreach (sort { lc($$IMediumRef{$a}) cmp lc($$IMediumRef{$b}) } (keys %$IMediumRef)) {
            my %mattr = (name       => 1,
                         logsize    => 1,
                         refresh    => 1,
                         accesserr  => 1,
                         location   => 1,
                         type       => 1); # medium attributes to get

            &get_imedium_attrs(\%mattr, $_);
            my $iter = $gui{treestoreVMMFloppy}->append(undef);

            if ($mattr{refresh} eq 'Inaccessible') {
                $gui{treestoreVMMFloppy}->set($iter, 0, $mattr{name},
                                                     1, $_,
                                                     2, 0,
                                                     3, $gui{img}{Error},
                                                     4, $mattr{accesserr}, # Tooltip can be access error
                                                     5, $mattr{location},
                                                     6, $mattr{type});
            }
            else {
                $gui{treestoreVMMFloppy}->set($iter, 0, $mattr{name},
                                                     1, $_,
                                                     2, &bytesToX($mattr{logsize}),
                                                     4, $mattr{location}, # Tooltip can be location
                                                     5, $mattr{location},
                                                     6, $mattr{type});
            }

            if ($_ eq $selected{IMedium}) {
                $gui{treeviewVMMFloppy}->get_selection()->select_iter($iter);
                &onsel_list_vmmfloppy();
            }
        }

        &busy_pointer($gui{dialogVMM}, 0);
    }

    sub onsel_list_vmmfloppy {
        my $model = $gui{treeviewVMMFloppy}->get_model();
        my $iter = $gui{treeviewVMMFloppy}->get_selection->get_selected() ? $gui{treeviewVMMFloppy}->get_selection->get_selected() : $model->get_iter_first();
        my @row = $model->get($iter);
        $selected{$_} = shift @row foreach ('Name', 'IMedium', 'Size', 'Accessible', 'Tooltip', 'Location', 'Type');
        $gui{toolbuttonVMMCopy}->set_sensitive(0);
        $gui{toolbuttonVMMModify}->set_sensitive(0);
        $gui{toolbuttonVMMCompact}->set_sensitive(0);

        my $gnames;
        my @mids = IMedium_getMachineIds($selected{IMedium});

        foreach my $id (@mids) {
            my $snames;
            my $IMachine = IVirtualBox_findMachine($gui{websn}, $id);
            my $mname = IMachine_getName($IMachine);
            my @sids = IMedium_getSnapshotIds($selected{IMedium}, $id);

            foreach my $snapid (@sids) {
                next if ($snapid eq $id);
                if (IMachine_getSnapshotCount($IMachine)) { # Just because the medium says its attached to a snapshot, that snapshot may not longer exist.
                    my $ISnapshot = IMachine_findSnapshot($IMachine, $snapid);
                    my $sname = ISnapshot_getName($ISnapshot) if ($ISnapshot);
                    $snames .= "$sname, " if ($sname);
                }
            }

            if ($snames) {
                $snames =~ s/, $//; # Remove any trailing comma
                $gnames .= "$mname ($snames). ";
            }
            else { $gnames .= "$mname, "; }
        }

        if ($gnames) {
            $gui{toolbuttonVMMRemove}->set_sensitive(0);
            $gui{toolbuttonVMMRelease}->set_sensitive(1);
            $gnames =~ s/, $//; # Remove any trailing comma
        }
        else {
            $gnames = '<Not Attached>';
            $gui{toolbuttonVMMRemove}->set_sensitive(1);
            $gui{toolbuttonVMMRelease}->set_sensitive(0);
        }

        &set_vmm_fields($gnames, \%selected);
    }
}

# VMM DVD List Handling
{
    my %selected = (IMedium => '');

    sub getsel_list_vmmdvd { return \%selected; }

    # Fill the DVD media list in the VMM
    sub fill_list_vmmdvd {
        &busy_pointer($gui{dialogVMM}, 1);
        &clr_list_vmm($gui{treestoreVMMDVD});
        my $IMediumRef = &get_all_media('DVD');

        foreach (sort { lc($$IMediumRef{$a}) cmp lc($$IMediumRef{$b}) } (keys %$IMediumRef)) {
            my %mattr = (name       => 1,
                         logsize    => 1,
                         refresh    => 1,
                         accesserr  => 1,
                         location   => 1,
                         type       => 1); # medium attributes to get

            &get_imedium_attrs(\%mattr, $_);
            my $iter = $gui{treestoreVMMDVD}->append(undef);

            if ($mattr{refresh} eq 'Inaccessible') {
                $gui{treestoreVMMDVD}->set($iter, 0, $mattr{name},
                                                  1, $_,
                                                  2, 0,
                                                  3, $gui{img}{Error},
                                                  4, $mattr{accesserr}, # Tooltip can be access error
                                                  5, $mattr{location},
                                                  6, $mattr{type});
            }
            else {
                $gui{treestoreVMMDVD}->set($iter, 0, $mattr{name},
                                                  1, $_,
                                                  2, &bytesToX($mattr{logsize}),
                                                  4, $mattr{location}, # Tooltip can be location
                                                  5, $mattr{location},
                                                  6, $mattr{type});
            }

            if ($_ eq $selected{IMedium}) {
                $gui{treeviewVMMDVD}->get_selection()->select_iter($iter);
                &onsel_list_vmmdvd();
            }
        }

        &busy_pointer($gui{dialogVMM}, 0);
    }

    sub onsel_list_vmmdvd {
        my $model = $gui{treeviewVMMDVD}->get_model();
        my $iter = $gui{treeviewVMMDVD}->get_selection->get_selected() ? $gui{treeviewVMMDVD}->get_selection->get_selected() : $model->get_iter_first();
        my @row = $model->get($iter);
        $selected{$_} = shift @row foreach ('Name', 'IMedium', 'Size', 'Accessible', 'Tooltip', 'Location', 'Type');
        $gui{toolbuttonVMMCopy}->set_sensitive(0);
        $gui{toolbuttonVMMModify}->set_sensitive(0);
        $gui{toolbuttonVMMCompact}->set_sensitive(0);

        my $gnames;
        my @mids = IMedium_getMachineIds($selected{IMedium});

        foreach my $id (@mids) {
            my $snames;
            my $IMachine = IVirtualBox_findMachine($gui{websn}, $id);
            my $mname = IMachine_getName($IMachine);
            my @sids = IMedium_getSnapshotIds($selected{IMedium}, $id);

            foreach my $snapid (@sids) {
                next if ($snapid eq $id);
                if (IMachine_getSnapshotCount($IMachine)) { # Just because the medium says its attached to a snapshot, that snapshot may not longer exist.
                    my $ISnapshot = IMachine_findSnapshot($IMachine, $snapid);
                    my $sname = ISnapshot_getName($ISnapshot) if ($ISnapshot);
                    $snames .= "$sname, " if ($sname);
                }
            }

            if ($snames) {
                $snames =~ s/, $//; # Remove any trailing comma
                $gnames .= "$mname ($snames). ";
            }
            else { $gnames .= "$mname, "; }
        }

        if ($gnames) {
            $gui{toolbuttonVMMRemove}->set_sensitive(0);
            $gui{toolbuttonVMMRelease}->set_sensitive(1);
            $gnames =~ s/, $//; # Remove any trailing comma
        }
        else {
            $gnames = '<Not Attached>';
            $gui{toolbuttonVMMRemove}->set_sensitive(1);
            $gui{toolbuttonVMMRelease}->set_sensitive(0);
        }

        &set_vmm_fields($gnames, \%selected);
    }
}

# IPv4 Port Forwarding List Handling
{
    my %selected = (Name => '');

    sub getsel_list_pf4 { return \%selected; }

    sub fill_list_pf4 {
        my ($INATNetwork) = @_;
        &busy_pointer($gui{dialogNATDetails}, 1);
        &clr_list_pf4();
        my @rules = INATNetwork_getPortForwardRules4($INATNetwork);
        foreach my $rule (@rules) {
            my ($rname, $rproto, $rhip, $rhport, $rgip, $rgport) = split ':', $rule;
            $rhip =~ s/[^0-9,.]//g; # Strip everything but these chars
            $rgip =~ s/[^0-9,.]//g; # Strip everything but these chars
            my $iter = $gui{liststorePFRulesIPv4}->append;
            $gui{liststorePFRulesIPv4}->set($iter, 0, $rname, 1, uc($rproto), 2, $rhip, 3, $rhport, 4, $rgip, 5, $rgport, 6, $INATNetwork);

            if ($rname eq $selected{Name}) {
                $gui{treeviewPFRulesIPv4}->get_selection()->select_iter($iter);
                &onsel_list_pf4();
            }
        }
        &busy_pointer($gui{dialogNATDetails}, 0);
    }

    sub onsel_list_pf4 {
        my $model = $gui{treeviewPFRulesIPv4}->get_model();
        my $iter = $gui{treeviewPFRulesIPv4}->get_selection->get_selected() ? $gui{treeviewPFRulesIPv4}->get_selection->get_selected() : $model->get_iter_first();
        my @row = $model->get($iter);
        $selected{$_} = shift @row foreach ('Name', 'Protocol', 'HostIP', 'HostPort', 'GuestIP', 'GuestPort', 'INATNetwork');
        $gui{buttonPFRulesRemove4}->set_sensitive(1);
    }

    sub clr_list_pf4 {
        $gui{liststorePFRulesIPv4}->clear();
        $gui{buttonPFRulesRemove4}->set_sensitive(0);
    }

}

# IPv6 Port Forwarding List Handling
{
    my %selected = (Name => '');

    sub getsel_list_pf6 { return \%selected; }

    sub fill_list_pf6 {
        my ($INATNetwork) = @_;
        &busy_pointer($gui{dialogNATDetails}, 1);
        &clr_list_pf6();
        my @rules = INATNetwork_getPortForwardRules6($INATNetwork);
        foreach my $rule (@rules) {
            # Jump through hoops because VB decided to use : as a column separator! Doh!
            $rule =~ s/\[(.*?)\]//;
            my $rhip = $1;
            $rule =~ s/\[(.*?)\]//;
            my $rgip = $1;
            my ($rname, $rproto, undef, $rhport, undef, $rgport) = split ':', $rule;
            my $iter = $gui{liststorePFRulesIPv6}->append;
            $gui{liststorePFRulesIPv6}->set($iter, 0, $rname, 1, uc($rproto), 2, $rhip, 3, $rhport, 4, $rgip, 5, $rgport, 6, $INATNetwork);

            if ($rname eq $selected{Name}) {
                $gui{treeviewPFRulesIPv6}->get_selection()->select_iter($iter);
                &onsel_list_pf6();
            }
        }
        &busy_pointer($gui{dialogNATDetails}, 0);
    }

    sub onsel_list_pf6 {
        my $model = $gui{treeviewPFRulesIPv6}->get_model();
        my $iter = $gui{treeviewPFRulesIPv6}->get_selection->get_selected() ? $gui{treeviewPFRulesIPv6}->get_selection->get_selected() : $model->get_iter_first();
        my @row = $model->get($iter);
        $selected{$_} = shift @row foreach ('Name', 'Protocol', 'HostIP', 'HostPort', 'GuestIP', 'GuestPort', 'INATNetwork');
        $gui{buttonPFRulesRemove6}->set_sensitive(1);
    }

    sub clr_list_pf6 {
        $gui{liststorePFRulesIPv6}->clear();
        $gui{buttonPFRulesRemove6}->set_sensitive(0);
    }

}

# VMM HD List Handling
{
    my %selected = (IMedium => '');

    sub getsel_list_vmmhd { return \%selected; }

    # Fill the hard disk media list in the VMM
    sub fill_list_vmmhd {
        &busy_pointer($gui{dialogVMM}, 1);
        &clr_list_vmm($gui{treestoreVMMHD});
        my $IMediumRef = &get_all_media('HardDisk');

        foreach (sort { lc($$IMediumRef{$a}) cmp lc($$IMediumRef{$b}) } (keys %$IMediumRef)) {
            &recurse_hd_snapshot($gui{treestoreVMMHD}, $_, undef);
        }

        &busy_pointer($gui{dialogVMM}, 0);
    }

    sub onsel_list_vmmhd {
        my $model = $gui{treeviewVMMHD}->get_model();
        my $iter = $gui{treeviewVMMHD}->get_selection->get_selected() ? $gui{treeviewVMMHD}->get_selection->get_selected() : $model->get_iter_first();
        my @row = $model->get($iter);
        $selected{$_} = shift @row foreach ('Name', 'IMedium', 'Asize', 'Vsize', 'Accessible', 'Tooltip', 'Location', 'Type', 'LsizeInt');
        $gui{toolbuttonVMMCopy}->set_sensitive(1);
        $gui{toolbuttonVMMModify}->set_sensitive(1);
        $gui{toolbuttonVMMCompact}->set_sensitive(1);

        my $gnames;
        my @mids = IMedium_getMachineIds($selected{IMedium});

        foreach my $id (@mids) {
            my $snames;
            my $IMachine = IVirtualBox_findMachine($gui{websn}, $id);
            my $mname = IMachine_getName($IMachine);
            my @sids = IMedium_getSnapshotIds($selected{IMedium}, $id);

            foreach my $snapid (@sids) {
                next if ($snapid eq $id);
                my $ISnapshot = IMachine_findSnapshot($IMachine, $snapid);
                my $sname = ISnapshot_getName($ISnapshot);
                $snames .= "$sname, ";
            }

            if ($snames) {
                $snames =~ s/, $//; # Remove any trailing comma
                $gnames .= "$mname ($snames). ";
            }
            else { $gnames .= "$mname, "; }
        }

        if ($gnames) {
            $gui{toolbuttonVMMRemove}->set_sensitive(0);
            $gui{toolbuttonVMMRelease}->set_sensitive(1);
            $gnames =~ s/, $//; # Remove any trailing comma
        }
        else {
            $gnames = '<Not Attached>';
            $gui{toolbuttonVMMRemove}->set_sensitive(1);
            $gui{toolbuttonVMMRelease}->set_sensitive(0);
        }

        # Don't allow remove/release if it has sub-snapshots
        if (IMedium_getChildren($selected{IMedium})) {
            $gui{toolbuttonVMMRemove}->set_sensitive(0);
            $gui{toolbuttonVMMRelease}->set_sensitive(0);
        }

        set_vmm_fields($gnames, \%selected);
    }

    # Recurses through the media for populating the VMM media lists, including
    # identifying snapshots
    sub recurse_hd_snapshot {
        my ($treestore, $IMedium, $iter) = @_;
        my %mattr = (name       => 1,
                     size       => 1,
                     logsize    => 1,
                     refresh    => 1,
                     accesserr  => 1,
                     children   => 1,
                     location   => 1,
                     type       => 1); # medium attributes to get

        &get_imedium_attrs(\%mattr, $IMedium);
        my $citer = $treestore->append($iter);

        if ($mattr{refresh} eq 'Inaccessible') {
            $treestore->set($citer, 0, $mattr{name},
                                    1, $IMedium,
                                    2, 0,
                                    3, 0,
                                    4, $gui{img}{Error},
                                    5, $mattr{accesserr},
                                    6, $mattr{location},
                                    7, $mattr{type},
                                    8, $mattr{logsize});
        }
        else {
            $treestore->set($citer, 0, $mattr{name},
                                    1, $IMedium,
                                    2, &bytesToX($mattr{size}),
                                    3, &bytesToX($mattr{logsize}),
                                    5, $mattr{location}, # Tooltip can be location
                                    6, $mattr{location},
                                    7, $mattr{type},
                                    8, $mattr{logsize});
        }

        if (($IMedium eq $selected{IMedium})) {
            $gui{treeviewVMMHD}->expand_all() if (IMedium_getParent($IMedium)); # If item is a snapshot, we need to expand the list in order for selection to work
            $gui{treeviewVMMHD}->get_selection()->select_iter($citer);
            &onsel_list_vmmhd();
        }

        &recurse_hd_snapshot($treestore, $_, $citer) foreach (@{$mattr{children}});
    }
}

# Sets the contents of the fields in the VMM
sub set_vmm_fields {
    my ($gnames, $selected) = @_;
    $gui{labelVMMTypeField}->set_text("$$selected{Type}, " . uc(IMedium_getFormat($$selected{IMedium})) . ', ' . IMedium_getVariant($$selected{IMedium}));
    $gui{labelVMMAttachedToField}->set_text($gnames);
    $gui{labelVMMLocationField}->set_text($$selected{Location});

    if (&imedium_has_property($$selected{IMedium}, 'CRYPT/KeyId')) { $gui{labelVMMEncryptedField}->set_text(IMedium_getProperty($$selected{IMedium}, 'CRYPT/#KeyId')); }
    else { $gui{labelVMMEncryptedField}->set_text('<Not Encrypted>'); }

    $gui{labelVMMUUIDField}->set_text(IMedium_getId($$selected{IMedium}));
}

sub clr_list_vmm {
    my ($treestore) = @_;
    &vmm_sens_unselected(); # Do whenever list is cleared
    $treestore->clear();
}

sub onsel_list_shared {
    $gui{buttonEditSharedRemove}->set_sensitive(1);
    $gui{buttonEditSharedEdit}->set_sensitive(1);
}

# Snapshot List Handling
{
    my %selected = (ISnapshot => '');

    sub getsel_list_snapshots { return \%selected; }

    # Set sensitivity when a snapshot is selected
    sub onsel_list_snapshots {
        my $model = $gui{treeviewSnapshots}->get_model();
        my $iter = $gui{treeviewSnapshots}->get_selection->get_selected() ? $gui{treeviewSnapshots}->get_selection->get_selected() : $model->get_iter_first();
        my @row = $model->get($iter);
        $selected{$_} = shift @row foreach ('Name', 'Date', 'ISnapshot', 'Icon');
        if ($selected{ISnapshot}) {
            $gui{buttonRestoreSnapshot}->set_sensitive(1);
            $gui{buttonDeleteSnapshot}->set_sensitive(1);
            $gui{buttonDetailsSnapshot}->set_sensitive(1);
            $gui{buttonCloneSnapshot}->set_sensitive(1);
            $gui{buttonTakeSnapshot}->set_sensitive(0);
        }
        else {
            $gui{buttonRestoreSnapshot}->set_sensitive(0);
            $gui{buttonDeleteSnapshot}->set_sensitive(0);
            $gui{buttonDetailsSnapshot}->set_sensitive(0);
            $gui{buttonCloneSnapshot}->set_sensitive(0);
            $gui{buttonTakeSnapshot}->set_sensitive(1);
        }
    }

    sub fill_list_snapshots {
        my $gref = &getsel_list_guest();
        &addrow_log("Fetching snapshots for $$gref{Name}...");
        &clr_list_snapshots();

        if (IMachine_getSnapshotCount($$gref{IMachine}) > 0) {
            my $ISnapshot_current = IMachine_getCurrentSnapshot($$gref{IMachine});
            my $ISnapshot = IMachine_findSnapshot($$gref{IMachine}, undef); # get first snapshot
            &recurse_snapshot($ISnapshot, undef, $ISnapshot_current);
            $gui{treeviewSnapshots}->expand_all();
        }

        &addrow_log('Snapshot fetch complete.');
    }

    # Clear snapshot list and set sensitivity
    sub clr_list_snapshots {
        $gui{buttonRestoreSnapshot}->set_sensitive(0);
        $gui{buttonDeleteSnapshot}->set_sensitive(0);
        $gui{buttonDetailsSnapshot}->set_sensitive(0);
        $gui{buttonCloneSnapshot}->set_sensitive(0);
        $gui{treestoreSnapshots}->clear();
    }

    sub recurse_snapshot {
        my ($ISnapshot, $iter, $ISnapshot_current) = @_;
        my $citer = $gui{treestoreSnapshots}->append($iter);
        my $snapname = ISnapshot_getName($ISnapshot);
        my $date = scalar(localtime((ISnapshot_getTimeStamp($ISnapshot))/1000)); # VBox returns msecs so / 1000
        $gui{treestoreSnapshots}->set($citer,
                                      0, $snapname,
                                      1, $date,
                                      2, $ISnapshot,
                                      3, &bl(ISnapshot_getOnline($ISnapshot)) ? $gui{img}{SnapshotOnline} : $gui{img}{SnapshotOffline});

        if ($ISnapshot eq $ISnapshot_current) {
            my $curiter = $gui{treestoreSnapshots}->append($citer);
            $gui{treestoreSnapshots}->set($curiter, 0, '[Current State]', 1, '', 2, '', 3, $gui{img}{SnapshotCurrent});
        }

        my @snapshots = ISnapshot_getChildren($ISnapshot);
        if (@snapshots > 0) { &recurse_snapshot($_, $citer, $ISnapshot_current) foreach (@snapshots); }
    }
}

# Guest List Handling
{
    my %selected = (Uuid => 'None'); # Initialize this element as it may be tested before the hash is fully initialized

    sub makesel_list_guest { $selected{Uuid} = $_[0]; }

    sub getsel_list_guest { return \%selected; }

    sub onsel_list_guest {
        &busy_pointer($gui{windowMain}, 1);
        my $model = $gui{treeviewGuest}->get_model();
        my $iter = $gui{treeviewGuest}->get_selection->get_selected() ? $gui{treeviewGuest}->get_selection->get_selected() : $model->get_iter_first();
        my @row = $model->get($iter);

        # If there's no IMachine, it's a group so don't waste anymore time
        if (!$row[2]) {
            &sens_unselected();
            $gui{treestoreDetails}->clear();
            &busy_pointer($gui{windowMain}, 0);
            return;
        }

        $selected{$_} = shift @row foreach ('Name', 'Os', 'IMachine', 'Status', 'Osid', 'Uuid', 'Icon', 'Prettyname', 'Statusicon');
        $prefs{EXTENDEDDETAILS} ? &fill_list_details() : &fill_list_details_brief();
        &sens_unselected();
        &fill_list_snapshots();
        my $status = IMachine_getState($selected{IMachine});

        if ($status eq 'Running' | $status eq 'Starting') {
            my @IMediumAttachment = IMachine_getMediumAttachments($selected{IMachine});
            my @IUSBController = IMachine_getUSBControllers($selected{IMachine});
            $gui{menuitemAction}->set_sensitive(1);
            $gui{menuitemStop}->set_sensitive(1);
            $gui{menuitemPause}->set_sensitive(1);
            $gui{menuitemReset}->set_sensitive(1);
            $gui{menuitemKeyboard}->set_sensitive(1);
            $gui{menuitemDisplay}->set_sensitive(1);
            $gui{menuitemLogs}->set_sensitive(1);
            $gui{toolbuttonStop}->set_sensitive(1);
            $gui{toolbuttonCAD}->set_sensitive(1);
            $gui{toolbuttonReset}->set_sensitive(1);
            $gui{toolbuttonRemoteDisplay}->set_sensitive(1);
            $gui{toolbuttonSettings}->set_sensitive(1);         # Online editing
            $gui{buttonRefreshSnapshot}->set_sensitive(1);
            $gui{buttonTakeSnapshot}->set_sensitive(1);
            $gui{menuitemScreenshot}->set_sensitive(1);
            $gui{menuitemUSB}->set_sensitive(1) if $IUSBController[0];
            $gui{menuitemHotPlugCPU}->set_sensitive(1) if (&bl(IMachine_getCPUHotPlugEnabled($selected{IMachine})));

            foreach my $attach (@IMediumAttachment) {
                $gui{menuitemDVD}->set_sensitive(1) if ($$attach{type} eq 'DVD');
                $gui{menuitemFloppy}->set_sensitive(1) if ($$attach{type} eq 'Floppy');
            }

        }
        elsif ($status eq 'Saved') {
            $gui{menuitemAction}->set_sensitive(1);
            $gui{menuitemStart}->set_sensitive(1);
            $gui{menuitemClone}->set_sensitive(1);
            $gui{menuitemLogs}->set_sensitive(1);
            $gui{menuitemDiscard}->set_sensitive(1);
            $gui{menuitemSetGroup}->set_sensitive(1);
            $gui{menuitemUngroup}->set_sensitive(1);
            $gui{toolbuttonStart}->set_sensitive(1);
            $gui{toolbuttonDiscard}->set_sensitive(1);
            $gui{buttonRefreshSnapshot}->set_sensitive(1);
            $gui{buttonTakeSnapshot}->set_sensitive(1);
        }
        elsif ($status eq 'Paused') {
            $gui{menuitemAction}->set_sensitive(1);
            $gui{menuitemStop}->set_sensitive(1);
            $gui{menuitemResume}->set_sensitive(1);
            $gui{menuitemRemoteDisplay}->set_sensitive(1);
            $gui{menuitemLogs}->set_sensitive(1);
            $gui{toolbuttonStop}->set_sensitive(1);
            $gui{toolbuttonRemoteDisplay}->set_sensitive(1);
            $gui{buttonRefreshSnapshot}->set_sensitive(1);
            $gui{buttonTakeSnapshot}->set_sensitive(1);
        }
        elsif ($status eq 'PoweredOff' | $status eq 'Aborted') {
            $gui{menuitemExportAppl}->set_sensitive(1);
            $gui{menuitemAction}->set_sensitive(1);
            $gui{menuitemStart}->set_sensitive(1);
            $gui{menuitemSettings}->set_sensitive(1);
            $gui{menuitemClone}->set_sensitive(1);
            $gui{menuitemRemove}->set_sensitive(1);
            $gui{menuitemSetGroup}->set_sensitive(1);
            $gui{menuitemUngroup}->set_sensitive(1);
            $gui{menuitemLogs}->set_sensitive(1);
            $gui{toolbuttonStart}->set_sensitive(1);
            $gui{toolbuttonSettings}->set_sensitive(1);
            $gui{buttonRefreshSnapshot}->set_sensitive(1);
            $gui{buttonTakeSnapshot}->set_sensitive(1);
            $gui{menuitemHotPlugCPU}->set_sensitive(0);
        }
        elsif ($status eq 'Stuck') {
               &sens_unselected();
               $gui{menuitemStop}->set_sensitive(1);
               $gui{toolbuttonStop}->set_sensitive(1);
        }
        else { &sens_unselected(); }

        &busy_pointer($gui{windowMain}, 0);
    }

    sub add_guest_group {
        my ($node, $name, $piter) = @_;

        if (defined($$node{$name})) { return $$node{$name}{node}, $$node{$name}{iter}; }
        else {
            my $citer = $gui{treestoreGuest}->append($piter);
            $gui{treestoreGuest}->set($citer, 0, $name,
                                              6, $gui{img}{VMGroup},
                                              7, $name);

            $$node{$name}{iter} = $citer;
            $$node{$name}{node} = {};
            return $$node{$name}{node}, $citer;
        }
    }

    # Populates the list of available guests
    sub fill_list_guest {
        my $osver = &osver();
        my %grouptree;
        &addrow_log("Fetching guest list from $endpoint...");
        &busy_pointer($gui{windowMain}, 1);
        &clr_list_guest();
        my %guestlist;
        my @IMachine = IVirtualBox_getMachines($gui{websn});
        my $selection;
        my $inaccessible = 0;

        # Preprocess groups first, leads to a neater layout as groups will all be added to the treeview
        # before the guests. Add iter to guestlist for use later to save us needing to look it up
        foreach my $machine (@IMachine) {
            my $node = \%grouptree; # Reset the tree to the start for each new guest

            if (&bl(IMachine_getAccessible($machine))) {
                $guestlist{$machine}{name} = IMachine_getName($machine);
                my ($group) = IMachine_getGroups($machine); # We only care about the first group returned
                $group =~ s/^\///; # Leading / is optional so always remove for simplicity
                my @components = split('/', $group);
                my $piter = undef;
                ($node, $piter) = &add_guest_group($node, $_, $piter) foreach (@components);
                $guestlist{$machine}{iter} = $piter;
            }
            else { $inaccessible = 1; }
        }

        # Lets sort the guest list according to preference
        my @machinelist;

        if ($prefs{AUTOSORTGUESTLIST}) {
            foreach my $m (sort { lc($guestlist{$a}{name}) cmp lc($guestlist{$b}{name}) } (keys %guestlist)) {
                push(@machinelist, $m);
            }
        }
        else { @machinelist = sort(keys %guestlist) };

        foreach my $machine (@machinelist) {
            my $ISnapshot = IMachine_getCurrentSnapshot($machine);
            my $osid = IMachine_getOSTypeId($machine);
            my $uuid = IMachine_getId($machine);
            my $prettyname = $guestlist{$machine}{name};
            my $status = IMachine_getState($machine);
            if ($ISnapshot) { $prettyname .=  ' (' . ISnapshot_getName($ISnapshot) . ")\n$status"; }
            else { $prettyname .=  "\n$status"; }

            my $iter = $gui{treestoreGuest}->append($guestlist{$machine}{iter});
            $gui{treestoreGuest}->set($iter,
                                      0, $guestlist{$machine}{name},
                                      1, $$osver{$osid}{description},
                                      2, $machine,
                                      3, $status,
                                      4, $osid,
                                      5, $uuid,
                                      6, (-e "$gui{THUMBDIR}/$uuid.png") ? Gtk2::Gdk::Pixbuf->new_from_file("$gui{THUMBDIR}/$uuid.png") : $$osver{$osid}{icon},
                                      7, $prettyname,
                                      8, $gui{img}{$status});

            $gui{treeviewGuest}->expand_all() if ($prefs{GUESTLISTEXPAND});
            $selection = $iter if ($uuid eq $selected{Uuid});
        }

        if ($selection) {
                $gui{treeviewGuest}->get_selection()->select_iter($selection);
                &onsel_list_guest();
        }

        &busy_pointer($gui{windowMain}, 0);
        &addrow_log('Guest list complete.');
        &addrow_log('WARNING: You have one or more guests that are inaccessible and have been excluded from ' .
                    'the guest list. You must use vboxmanage or VirtualBox on the server to fix these issues') if ($inaccessible);

        &update_server_membar();
    }

    sub clr_list_guest {
        &sens_unselected();
        $gui{treestoreGuest}->clear();
        $gui{treestoreDetails}->clear();
        &clr_list_snapshots();
    }
}

# Block handling profiles
{
    my %selected = (Name => '');

    # If pname exists we're calling this method directly, otherwise we're calling it from the button
    sub addrow_profile {
        my ($widget, $pname, $url, $username, $password) = @_;
        my $iter = $gui{liststoreProfiles}->append;

        if ($pname) {
            $gui{liststoreProfiles}->set($iter, 0, $pname,
                                                1, $url,
                                                2, $username,
                                                3, $password);
        }
        else {
            $pname = 'Unnamed' . int(rand(9999));
            $gui{liststoreProfiles}->set($iter, 0, $pname,
                                            1, 'http://localhost:18083',
                                            2, '',
                                            3, '');
            $gui{treeviewConnectionProfiles}->get_selection()->select_iter($iter);
            &onsel_list_profile();
        }
    }

    sub getsel_list_profile { return \%selected; }

    sub onsel_list_profile {
        my $model = $gui{treeviewConnectionProfiles}->get_model();
        my $iter = $gui{treeviewConnectionProfiles}->get_selection->get_selected() ? $gui{treeviewConnectionProfiles}->get_selection->get_selected() : $model->get_iter_first();
        my @row = $model->get($iter);
        $selected{$_} = shift @row foreach ('Name', 'URL', 'Username', 'Password');
        $gui{entryPrefsConnectionProfileName}->set_text($selected{Name});
        $gui{entryPrefsConnectionProfileURL}->set_text($selected{URL});
        $gui{entryPrefsConnectionProfileUsername}->set_text($selected{Username});
        $gui{entryPrefsConnectionProfilePassword}->set_text($selected{Password});
        $gui{checkbuttonConnectionProfileAutoConnect}->set_active(1) if ($selected{Name} eq $prefs{AUTOCONNPROF});
        $gui{checkbuttonConnectionProfileAutoConnect}->set_active(0) if ($selected{Name} ne $prefs{AUTOCONNPROF});
        $gui{buttonPrefsConnectionProfileDelete}->set_sensitive(1);
        $gui{tablePrefsProfile}->set_sensitive(1);
    }

    # Delete a connection profile
    sub remove_profile {
        my ($widget) = @_;
        my $model = $gui{treeviewConnectionProfiles}->get_model();
        my $iter = $gui{treeviewConnectionProfiles}->get_selection->get_selected();
        my $nextiter = $model->iter_next($iter);

        if ($gui{liststoreProfiles}->iter_is_valid($iter)) {
            $gui{entryPrefsConnectionProfileName}->set_text('');
            $gui{entryPrefsConnectionProfileURL}->set_text('');
            $gui{entryPrefsConnectionProfileUsername}->set_text('');
            $gui{entryPrefsConnectionProfilePassword}->set_text('');
            $gui{liststoreProfiles}->remove($iter);
            $gui{buttonPrefsConnectionProfileDelete}->set_sensitive(0);
            $gui{tablePrefsProfile}->set_sensitive(0);
        }

        if ($nextiter) {
            $gui{treeviewConnectionProfiles}->get_selection()->select_iter($nextiter);
            &onsel_list_profile();
        }
    }

    sub profile_name_change {
        my $model = $gui{treeviewConnectionProfiles}->get_model();
        my $iter = $gui{treeviewConnectionProfiles}->get_selection->get_selected();
        $gui{liststoreProfiles}->set_value($iter, 0, $gui{entryPrefsConnectionProfileName}->get_text()) if ($iter);
    }

    sub profile_url_change {
        my $model = $gui{treeviewConnectionProfiles}->get_model();
        my $iter = $gui{treeviewConnectionProfiles}->get_selection->get_selected();
        $gui{liststoreProfiles}->set_value($iter, 1, $gui{entryPrefsConnectionProfileURL}->get_text()) if ($iter);
    }

    sub profile_username_change {
        my $model = $gui{treeviewConnectionProfiles}->get_model();
        my $iter = $gui{treeviewConnectionProfiles}->get_selection->get_selected();
        $gui{liststoreProfiles}->set_value($iter, 2, $gui{entryPrefsConnectionProfileUsername}->get_text()) if ($iter);
    }

    sub profile_password_change {
        my $model = $gui{treeviewConnectionProfiles}->get_model();
        my $iter = $gui{treeviewConnectionProfiles}->get_selection->get_selected();
        $gui{liststoreProfiles}->set_value($iter, 3, $gui{entryPrefsConnectionProfilePassword}->get_text()) if ($iter);
    }

    sub profile_autoconn_change {
        my $state = $gui{checkbuttonConnectionProfileAutoConnect}->get_active();
        if ($state) { $prefs{AUTOCONNPROF} = $gui{entryPrefsConnectionProfileName}->get_text(); }
        else {
            # Only clear it, if the profilename matches the auto connection name
            $prefs{AUTOCONNPROF} = '' if ( $prefs{AUTOCONNPROF} eq $gui{entryPrefsConnectionProfileName}->get_text() );
        }
    }
}

1;
