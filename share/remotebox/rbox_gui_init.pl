# General GUI related functions and structures
use strict;
use warnings;
use File::Spec;
use File::Spec::Functions;
use File::Spec::Win32;
use File::Spec::Unix;
use Getopt::Std;
use Gtk2 '-init';
our $sharedir;

my $builder = Gtk2::Builder->new;
$builder->add_from_file("$sharedir/remotebox.xml");
$builder->connect_signals();

our %gui = (textbufferEditGenDescription         => $builder->get_object('textbufferEditGenDescription'),
            textbufferSnapshotDescription        => $builder->get_object('textbufferSnapshotDescription'),
            textbufferSnapshotDetailsDescription => $builder->get_object('textbufferSnapshotDetailsDescription'),
            textbufferEditNetGeneric             => $builder->get_object('textbufferEditNetGeneric'),
            textbufferExportApplDescription      => $builder->get_object('textbufferExportApplDescription'),
            textbufferExportApplLicense          => $builder->get_object('textbufferExportApplLicense'),
            adjustmentEditSysProcessor           => $builder->get_object('adjustmentEditSysProcessor'),
            adjustmentEditSysProcessorCap        => $builder->get_object('adjustmentEditSysProcessorCap'),
            adjustmentEditStorPortCount          => $builder->get_object('adjustmentEditStorPortCount'),
            adjustmentPFIPHostPort               => $builder->get_object('adjustmentPFIPHostPort'),
            adjustmentPFIPGuestPort              => $builder->get_object('adjustmentPFIPGuestPort'),
            appname                              => $builder->get_object('aboutdialog')->get_program_name(),
            appver                               => $builder->get_object('aboutdialog')->get_version(),
            vboxEditIOPorts                      => $builder->get_object('vboxEditIOPorts'),
            websn                                => undef);

# Guest Status
$gui{img}{Aborted} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Aborted.png");
$gui{img}{DeletingSnapshot} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Misc.png");
$gui{img}{DeletingSnapshotOnline} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Misc.png");
$gui{img}{DeletingSnapshotPaused} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Misc.png");
$gui{img}{Discarding} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Discarding.png");
$gui{img}{Error} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Error.png");
$gui{img}{FaultTolerantSyncing} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Misc.png");
$gui{img}{FirstOnline} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Running.png");
$gui{img}{FirstTransient} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Running.png");
$gui{img}{LastOnline} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Running.png");
$gui{img}{LastTransient} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Running.png");
$gui{img}{LiveSnapshotting} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Misc.png");
$gui{img}{OnlineSnapshotting} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Misc.png");
$gui{img}{Paused} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Paused.png");
$gui{img}{PoweredOff} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/PoweredOff.png");
$gui{img}{Restoring} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Restoring.png");
$gui{img}{RestoringSnapshot} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Restoring.png");
$gui{img}{Running} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Running.png");
$gui{img}{Saved} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Saved.png");
$gui{img}{Saving} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Saving.png");
$gui{img}{SettingUp} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Running.png");
$gui{img}{Snapshotting} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Misc.png");
$gui{img}{Starting} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Running.png");
$gui{img}{Stopping} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Misc.png");
$gui{img}{Stuck} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Stuck.png");
$gui{img}{Teleported} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/PoweredOff.png");
$gui{img}{Teleporting} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Misc.png");
$gui{img}{TeleportingIn} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Misc.png");
$gui{img}{TeleportingPausedVM} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Paused.png");
# Storage Icons
$gui{img}{Network} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/nw_16px.png");
$gui{img}{HardDisk} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/hd_16px.png");
$gui{img}{DVD} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/cd_16px.png");
$gui{img}{Floppy} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/fd_16px.png");
$gui{img}{ctr}{IDE} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/ide_16px.png");
$gui{img}{ctr}{SATA} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/sata_16px.png");
$gui{img}{ctr}{SAS} = $gui{img}{ctr}{SATA};
$gui{img}{ctr}{SCSI} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/scsi_16px.png");
$gui{img}{ctr}{Floppy} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/floppy_16px.png");
$gui{img}{ctr}{USB} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/usb_16px.png");
$gui{img}{ctr}{PCIe} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/nvme_16px.png");
# Snapshot icons
$gui{img}{SnapshotOffline} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/snapshot_offline_16px.png");
$gui{img}{SnapshotOnline} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/snapshot_online_16px.png");
$gui{img}{SnapshotCurrent} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/machine_16px.png");
# OS Icons
$gui{img}{OtherOS} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/os/Other.png");
$gui{img}{OtherOS64} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/os/Other_64.png");
# Other Icons
$gui{img}{VMGroup} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/vm_group_16px.png");
$gui{img}{DirIcon} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/sf_16px.png");
$gui{img}{FileIcon} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/vm_open_filemanager_16px.png");
$gui{img}{ParentIcon} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/sf_parent_16px.png");
# Details Icons
$gui{img}{CatGen} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/machine_16px.png");
$gui{img}{CatSys} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/chipset_16px.png");
$gui{img}{CatDisp} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/vrdp_16px.png");
$gui{img}{CatStor} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/hd_16px.png");
$gui{img}{CatAudio} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/sound_16px.png");
$gui{img}{CatNet} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/nw_16px.png");
$gui{img}{CatIO} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/serial_port_16px.png");
$gui{img}{CatUSB} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/usb_16px.png");
$gui{img}{CatShare} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/sf_16px.png");
$gui{img}{CatDesc} = Gtk2::Gdk::Pixbuf->new_from_file("$sharedir/icons/description_16px.png");

our %prefs;

# Fill %gui so we can reference them easily.
foreach ($builder->get_objects) {
    my $id;
    eval{ $id = $_->Gtk2::Buildable::get_name; }; # DONT USE $_->get_name()
    $gui{$id} = $_ if ($id);
}

# We have to register signals manually, which we want to block at some point because we need the sigids
# as blocking any other way is not supported in perl-gtk (other blocking funcs map to null funcs)
our %signal = (fam                => $gui{comboboxNewOSFam}->signal_connect(changed => \&newgen_osfam, $gui{comboboxNewOSVer}),
               ver                => $gui{comboboxNewOSVer}->signal_connect(changed => \&newgen_osver, $gui{comboboxNewOSFam}),
               famedit            => $gui{comboboxEditGenOSFam}->signal_connect(changed => \&gen_osfam, $gui{comboboxEditGenOSVer}),
               veredit            => $gui{comboboxEditGenOSVer}->signal_connect(changed => \&gen_osver, $gui{comboboxEditGenOSFam}),
               audiodrv           => $gui{comboboxEditAudioDriver}->signal_connect(changed => \&audio_driver),
               audioctr           => $gui{comboboxEditAudioCtr}->signal_connect(changed => \&audio_ctr),
               audiocodec         => $gui{comboboxEditAudioCodec}->signal_connect(changed => \&audio_codec),
               netadaptype        => $gui{comboboxEditNetType}->signal_connect(changed => \&net_adapter_type, $gui{checkbuttonEditNetEnable}),
               netattach          => $gui{comboboxEditNetAttach}->signal_connect(changed => \&net_attach, $gui{checkbuttonEditNetEnable}),
               netname            => $gui{comboboxEditNetName}->signal_connect(changed => \&net_name, $gui{checkbuttonEditNetEnable}),
               genericdrv         => $gui{comboboxentryEditNetGenDriver}->signal_connect(changed => \&net_generic_driver, $gui{checkbuttonEditNetEnable}),
               nameint            => $gui{comboboxentryEditNetNameInt}->signal_connect(changed => \&net_name_internal, $gui{checkbuttonEditNetEnable}),
               stortype           => $gui{comboboxEditStorCtrType}->signal_connect(changed => \&storage_ctrtype),
               usbtoggle          => $gui{checkbuttonEditUSBEnable}->signal_connect(toggled => \&usb_toggle),
               snapfolderactivate => $gui{entryEditGenSnapFolder}->signal_connect(activate => \&gen_snapfolder),
               snapfolderfocus    => $gui{entryEditGenSnapFolder}->signal_connect(activate => \&gen_snapfolder));

# Work around a stupid bug in Glade 3.10.x that disables toolbutton menus
$gui{toolbuttonStop}->set_menu($gui{menuStop});
$gui{toolbuttonCAD}->set_menu($gui{menuKeyboardMini});

# Work around another bug in Glade, setting selection mode does not work
$gui{treeviewInfo}->get_selection->set_mode('GTK_SELECTION_NONE');
$gui{treeviewEvalConfig}->get_selection->set_mode('GTK_SELECTION_NONE');

# Transient Window Handling
# A windows transient is automatically set on open
{
    my @winlist = ($gui{windowMain});

    # Set the transient window's (ie parent window) sensitivity on
    sub transwin_sens_on {
        my ($win) = @_;
        pop @winlist;
        my $transwin = $win->get_transient_for();
        $transwin->set_sensitive(1) if ($transwin);
    }

    # Set the transient window's (ie parent window) sensitivity off
    sub transwin_sens_off {
        my ($win) = @_;
        my $transwin = $winlist[$#winlist]; # Get the last opened window
        push @winlist, $win;
        $win->set_transient_for($transwin) if ($transwin);
        $transwin->set_sensitive(0) if ($transwin);
    }
}

# Ghosts window and optionally sets pointer
sub busy_window {
    my ($window, $sens, $pointer) = @_;
    $window->set_sensitive($sens);

    if ($pointer) { eval { $window->window->set_cursor(Gtk2::Gdk::Cursor->new($pointer)); }; }
    else { eval{ $window->window->set_cursor(undef); }; }

    Gtk2->main_iteration() while Gtk2->events_pending();
}

# Busy the pointer only
sub busy_pointer {
    my ($window, $pointer) = @_;
    if ($pointer) { eval { $window->window->set_cursor(Gtk2::Gdk::Cursor->new('watch')); }; }
    else { eval{ $window->window->set_cursor(undef); }; }
    Gtk2->main_iteration() while Gtk2->events_pending();
}

sub handle_bioslogofilechooser {
    my ($basedir, $filename) = @_;
    if ($basedir and $filename) {
        $gui{entryEditSysLogoPath}->set_text(&rcatfile($basedir, $filename));
        &sys_bioslogopath();
    }
}

sub handle_videofilechooser {
    my ($basedir, $filename) = @_;
    if ($basedir and $filename) {
        $gui{entryEditDispCapturePath}->set_text(&rcatfile($basedir, $filename));
        &sys_capturepath();
    }
}

sub handle_machinefolderchooser {
    my ($location, $filearrayref) = @_;
    my $file = ${$filearrayref}[0]->{FileName};
    my $type = ${$filearrayref}[0]->{Type};

    # Depending on what the user does, there will either be an additional directory
    # to append or not. Type (Dir) already excludes (Parent)
    $location = &rcatdir($location, $file) if ($file and $type eq '(Dir)');
    $gui{entryVBPrefsGenMachineFolder}->set_text($location) if ($location);
}

sub handle_autostartfolderchooser {
    my ($location, $filearrayref) = @_;
    my $file = ${$filearrayref}[0]->{FileName};
    my $type = ${$filearrayref}[0]->{Type};

    # Depending on what the user does, there will either be an additional directory
    # to append or not. Type (Dir) already excludes (Parent)
    $location = &rcatdir($location, $file) if ($file and $type eq '(Dir)');
    $gui{entryVBPrefsGenAutostartDBFolder}->set_text($location) if ($location);
}

sub handle_snapshotfolderchooser {
    my ($location, $filearrayref) = @_;
    my $file = ${$filearrayref}[0]->{FileName};
    my $type = ${$filearrayref}[0]->{Type};

    # Depending on what the user does, there will either be an additional directory
    # to append or not. Type (Dir) already excludes (Parent)
    $location = &rcatdir($location, $file) if ($file and $type eq '(Dir)');
    $gui{entryEditGenSnapFolder}->set_text($location) if ($location);
    &gen_snapfolder();
}

sub handle_sharedfolderchooser {
    my ($location, $filearrayref) = @_;
    my $file = ${$filearrayref}[0]->{FileName};
    my $type = ${$filearrayref}[0]->{Type};

    # Depending on what the user does, there will either be an additional directory
    # to append or not. Type (Dir) already excludes (Parent)
    $location = &rcatdir($location, $file) if ($file and $type eq '(Dir)');
    $gui{entrySharedFolderPath}->set_text($location) if ($location);
}

sub handle_vboxfilechooser {
    my ($basedir, $filename) = @_;

    if ($basedir and $filename) {
        my $vboxfile = &rcatfile($basedir, $filename);
        my $IMachine = IVirtualBox_openMachine($gui{websn}, $vboxfile);
        if ($IMachine) {
            IVirtualBox_registerMachine($gui{websn}, $IMachine);
            &addrow_log("Imported guest from $vboxfile");
            &fill_list_guest();
        }
        else { &addrow_log("Failed to import guest from $vboxfile"); }
    }
}

# Handle select the appliance file to export to from the file chooser
sub handle_exportapplfilechooser {
    my ($basedir, $filename) = @_;

    if ($basedir and $filename) {
        $filename .= '.ova' if ($filename !~ m/.ovf$/i and $filename !~ m/.ova$/i);
        $gui{entryExportApplFile}->set_text(&rcatfile($basedir, $filename));
    }
}

# Handles appliance files and imports them
sub handle_importapplfilechooser {
    my ($basedir, $filename) = @_;

    $gui{entryImportApplFile}->set_text(&rcatfile($basedir, $filename)) if ($basedir and $filename);
}


# Sets up the file chooser for selecting a BMP files
sub show_bioslogofilechooser {
    my ($vol, $dir, $file) = &rsplitpath($gui{entryEditSysLogoPath}->get_text());

    &show_remotefilechooser_window({title     => "Choose BMP file on $endpoint",
                                    basedir   => $vol . $dir,
                                    filename  => $file,
                                    mode      => 'file',
                                    filter    => '^.*\.bmp$', # To only show bmp files
                                    handler   => \&handle_bioslogofilechooser});
}


# Sets up the file chooser for selecting the video file directory
sub show_videofilechooser {
    my ($vol, $dir, $file) = &rsplitpath($gui{entryEditDispCapturePath}->get_text());

    &show_remotefilechooser_window({title     => "Choose capture file on $endpoint",
                                    basedir   => $vol . $dir,
                                    filename  => $file,
                                    mode      => 'file',
                                    filter    => '^.*\.webm$', # To only show webm files
                                    handler   => \&handle_videofilechooser});
}

# Sets up the file chooser for selecting the file to export the appliance to
sub show_exportapplfilechooser {
    my ($vol, $dir, $file) = &rsplitpath($gui{entryExportApplFile}->get_text());

    &show_remotefilechooser_window({title     => "Choose OVF/OVA file on $endpoint",
                                    basedir   => $vol . $dir,
                                    filename  => $file,
                                    mode      => 'file',
                                    filter    => '^.*\.ov[a|f]$', # To only show ova/ovf files
                                    handler   => \&handle_exportapplfilechooser});
}

# Sets up the file chooser for selecting the appliance
{
    my $startloc = $gui{entryVBPrefsGenMachineFolder}->get_text();

    sub show_importapplfilechooser {
        $startloc = &show_remotefilechooser_window({title     => "Choose OVF/OVA file on $endpoint",
                                                    basedir   => $startloc,
                                                    filename  => '',
                                                    mode      => 'file',
                                                    filter    => '^.*\.ov[a|f]$', # To only show ova/ovf files
                                                    handler   => \&handle_importapplfilechooser});
    }
}

# Sets up the file chooser for selecting a VBOX file
{
    my $startloc = $gui{entryVBPrefsGenMachineFolder}->get_text();

    sub show_vboxfilechooser {
        $startloc = &show_remotefilechooser_window({title     => "Choose guest to add on $endpoint",
                                                    basedir   => $startloc,
                                                    filename  => '',
                                                    mode      => 'file',
                                                    filter    => '^.*\.vbox$', # To only show vbox files
                                                    handler   => \&handle_vboxfilechooser});
    }
}

# Sets up the file chooser for selecting a medium (or any file actually)
{
    my $startloc = $gui{entryVBPrefsGenMachineFolder}->get_text();

    sub show_vmmfilechooser {
        $startloc = &show_remotefilechooser_window({title     => "Choose Media Images on $endpoint",
                                                    basedir   => $startloc,
                                                    filename  => '',
                                                    mode      => 'multifile',
                                                    filter    => '.*', # Allow any file
                                                    handler   => \&vmm_add});
    }
}

# Sets up the file chooser for selecting the default machine directory
{
    my $startloc = $gui{entryVBPrefsGenMachineFolder}->get_text();

    sub show_machinefolderchooser {
        $startloc = &show_remotefilechooser_window({title     => "Choose Machine Folder on $endpoint",
                                                    basedir   => $startloc,
                                                    filename  => '',
                                                    mode      => 'dir',
                                                    filter    => ' ^', # To only show directories
                                                    handler   => \&handle_machinefolderchooser});
    }
}

# Sets up the file chooser for selecting the autostart database directory
{
    my $startloc = $gui{entryVBPrefsGenAutostartDBFolder}->get_text();

    sub show_autostartfolderchooser {
        $startloc = &show_remotefilechooser_window({title     => "Choose Autostart Database Folder on $endpoint",
                                                    basedir   => $startloc,
                                                    filename  => '',
                                                    mode      => 'dir',
                                                    filter    => ' ^', # To only show directories
                                                    handler   => \&handle_autostartfolderchooser});
    }
}

# Sets up the file chooser for selecting the snapshot directory
{
    my $startloc = $gui{entryEditGenSnapFolder}->get_text();

    sub show_snapshotfolderchooser {
        $startloc = &show_remotefilechooser_window({title     => "Choose Snapshot Folder on $endpoint",
                                                    basedir   => $startloc,
                                                    filename  => '',
                                                    mode      => 'dir',
                                                    filter    => ' ^', # To only show directories
                                                    handler   => \&handle_snapshotfolderchooser});
    }
}

# Sets up the file chooser for selecting a shared folder
{
    my $startloc = $gui{entrySharedFolderPath}->get_text();

    sub show_sharedfolderchooser {
        $startloc = &show_remotefilechooser_window({title     => "Choose Shared Folder on $endpoint",
                                                    basedir   => $startloc,
                                                    filename  => '',
                                                    mode      => 'dir',
                                                    filter    => ' ^', # To only show directories
                                                    handler   => \&handle_sharedfolderchooser});
    }
}

sub show_remotefilechooser_window {
    my ($param) = @_;
    my $vhost = &vhost();

    $gui{dialogRemoteFileChooser}->set_title($$param{title});
    $gui{entryRemoteFileChooserFilter}->set_text($$param{filter});
    $$param{basedir} = $$vhost{machinedir} unless ($$param{basedir});

    if ($$param{mode} eq 'dir') {
        $gui{treeviewRemoteFileChooser}->get_selection->set_mode('GTK_SELECTION_SINGLE');
        $gui{hboxRemoteFileChooserFile}->hide();
    }
    elsif ($$param{mode} eq 'multifile') {
        $gui{treeviewRemoteFileChooser}->get_selection->set_mode('GTK_SELECTION_MULTIPLE');
        $gui{hboxRemoteFileChooserFile}->hide();
    }
    else {
        $gui{treeviewRemoteFileChooser}->get_selection->set_mode('GTK_SELECTION_SINGLE');
        $gui{entryRemoteFileChooserFile}->set_text($$param{filename});
        $gui{hboxRemoteFileChooserFile}->show();
    }

    my $IAppliance = IVirtualBox_createAppliance($gui{websn});
    $gui{IVFSExplorer} = IAppliance_createVFSExplorer($IAppliance, "file://$$param{basedir}");
    &fill_list_remotefiles($$param{basedir}, $$param{filter});
    my $response = $gui{dialogRemoteFileChooser}->run();
    $gui{dialogRemoteFileChooser}->hide();
    IManagedObjectRef_release($gui{IVFSExplorer});
    IManagedObjectRef_release($IAppliance);

    if ($response eq 'ok') {
        my $location = $gui{entryRemoteFileChooserLocation}->get_text();
        my $filename = $gui{entryRemoteFileChooserFile}->get_text();
        if ($$param{mode} eq 'file') { &{$$param{handler}}($location, $filename) }
        else {
            my $filearrayref;
            $filearrayref = &getsel_list_remotefiles();
            &{$$param{handler}}($location, $filearrayref);
        }
    }

    return $gui{entryRemoteFileChooserLocation}->get_text();
}

sub refresh_remotefilechooser { &fill_list_remotefiles($gui{entryRemoteFileChooserLocation}->get_text(), $gui{entryRemoteFileChooserFilter}->get_text()); }

sub cdup_remotefilechooser {
    IVFSExplorer_cdUp($gui{IVFSExplorer});
    &fill_list_remotefiles(IVFSExplorer_getPath($gui{IVFSExplorer}), $gui{entryRemoteFileChooserFilter}->get_text());
}

# Display a progress window for tasks which can take a long time
sub show_progress_window {
    my ($IProgress, $msg) = @_;
    my $resultcode = 0;
    my $timer = 0;
    $gui{dialogProgress}->set_title($msg);
    $gui{labelProgress}->set_text(''); # Reset text so its not cached from a previous call
    $gui{progressbar}->set_text(''); # Reset text so its not cached from a previous call
    $gui{progressbar}->set_fraction(0); # Reset fraction back to 0
    (IProgress_getCancelable($IProgress) eq 'true') ? $gui{buttonProgressCancel}->show() : $gui{buttonProgressCancel}->hide();
    Gtk2->main_iteration() while Gtk2->events_pending();

    $timer = Glib::Timeout->add(1000,
        sub {
            $gui{buttonProgressCancel}->hide() if (IProgress_getCancelable($IProgress) eq 'false'); # Sometimes cancellable earlier but not later on
            my $percent = IProgress_getPercent($IProgress);
            my $secsremaining = IProgress_getTimeRemaining($IProgress);
            $gui{labelProgress}->set_text(IProgress_getOperationDescription($IProgress));
            if (IProgress_getCompleted($IProgress) eq 'true') {
                Glib::Source->remove($timer);
                $timer = 0;
                $gui{progressbar}->set_fraction(1.00);
                $gui{progressbar}->set_text('100%');
                $resultcode = IProgress_getResultCode($IProgress);
                $gui{dialogProgress}->response('ok');
                return 0;
            }
            else {

                $gui{progressbar}->set_fraction($percent * 0.01);
                if ($percent > 10 and $secsremaining > 0) {
                    my $humantime = &secs_to_humantime($secsremaining);
                    $gui{progressbar}->set_text("$percent% (About $humantime remaining)");
                }
                else { $gui{progressbar}->set_text("$percent%"); }
                return 1;
            }
        });

    my $response = $gui{dialogProgress}->run();
    $gui{dialogProgress}->hide();
    Glib::Source->remove($timer) if ($timer);
    IProgress_cancel($IProgress) if ($response ne 'ok');
    Gtk2->main_iteration() while Gtk2->events_pending();
    return $resultcode;
}

# Restore RemoteBox's window position to the last save position
sub restore_window_pos {
    my ($winname) = @_;

    if ($prefs{"WINPOS_$winname"}) {
        my ($w, $h, $x, $y) = split ':', $prefs{"WINPOS_$winname"};
        $gui{$winname}->move($x, $y);
        $gui{$winname}->resize($w, $h);
    }
}

# Permit certain chars only for a guest name
sub validate_name {
    my ($entry, $char, $len, $pos) = @_;
    $char =~ s/[\?\/\;\*\\\<\>\|\.]//; # Strip these chars
    return $char, $pos;
}

# Permite certain chats only for group names
sub validate_group {
    my ($entry, $char, $len, $pos) = @_;
    $char = '' if ($char !~ m/[a-z]|[A-Z]|\//); # Strip all which doesn't match this
    return $char, $pos;
}

# Basic character validation for hexadecial
sub validate_hex {
    my ($entry, $char, $len, $pos) = @_;
    $char =~ s/[^A-F0-9a-f]//; # Strip everything but these chars
    return $char, $pos;
}

# Basic character validation for a port range
sub validate_port {
    my ($entry, $char, $len, $pos) = @_;
    $char =~ s/[^0-9,-]//; # Strip everything but these chars
    return $char, $pos;
}

# Permit only numbers in an entry
sub validate_number {
    my ($entry, $char, $len, $pos) = @_;
    $char =~ s/[^0-9]//; # Strip everything but these chars
    return $char, $pos;
}

# Basic character validation for IPv4
sub validate_ipv4 {
    my ($entry, $char, $len, $pos) = @_;
    $char =~ s/[^0-9,.]//; # Strip everything but these chars
    return $char, $pos;
}

# Basic character validation for IPv6
sub validate_ipv6 {
    my ($entry, $char, $len, $pos) = @_;
    $char =~ s/[^A-F0-9a-f,:]//; # Strip everything but these chars
    return $char, $pos;
}

# Basic character validation for CIDR
sub validate_cidr {
    my ($entry, $char, $len, $pos) = @_;
    $char =~ s/[^0-9,.,\/]//; # Strip everything but these chars
    return $char, $pos;
}

# Is it valid IPv4 CIDR format
sub valid_cidr {
    return 1 if ($_[0] =~ m/^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\/(\d|[1-2]\d|3[0-2]))$/);
}

# Is it a valid IPv4 address
sub valid_ipv4 {
    return 1 if ($_[0] =~ m/^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$/);
}

# Is it a valid IPv6 address. Needs fixing
sub valid_ipv6 { return 1; }

sub combobox_set_active_text {
    my ($combobox, $text) = @_;
    my $i = -1;
    $combobox->get_model->foreach (
                            sub {
                                my ($model, $path, $iter) = @_;
                                if ($text eq $model->get_value($iter, 0)) {
                                    ($i) = $path->get_indices;
                                    return 1; # stop
                                }
                                return 0; # continue
                            }
                          );
    $combobox->set_active($i);
}

# Adds appropriate units to a spinbox when specifying memory or disk
sub spinbox_bytes_out {
    my ($widget) = @_;
    my $txt = $widget->get_text();
    my $adjustment = $widget->get_adjustment();
    my $adjval = int($adjustment->get_value());

    if ($adjval < 1024) {
        $adjustment->step_increment(1.00);
        $txt = "$adjval MB";
    }
    elsif ($adjval < 1048576) {
        $adjustment->step_increment(10.25);
        $adjval /= 1024;
        $txt = sprintf('%0.2f GB', $adjval);
    }
    else {
        $adjustment->step_increment(10486);
        $adjval /= 1048576;
        $txt = sprintf('%0.2f TB', $adjval);
    }

    $widget->set_text($txt);
    return 1;
}

# Parses the input and assumes m is mega, g is Giga and t is tera
sub spinbox_bytes_in {
    my ($widget) = @_;
    my $txt = $widget->get_text();

    if ($txt =~ m/m/i) {
        $txt =~ s/[^\d.]//g; # Strip all except digits and .
        $txt =~ s/\.+/\./; # Handle many . here but wont catch 3.5.3.5 for example
        $widget->get_adjustment->set_value(int($txt)); # Force to be an integer, can't have <1MB
    }
    elsif ($txt =~ m/g/i) {
        $txt =~ s/[^\d.]//g; # Strip all except digits and .
        $txt =~ s/\.+/\./; # Handle many . here but wont catch 3.5.3.5 for example
        $txt = ($txt * 1024);
        $widget->get_adjustment->set_value($txt);
    }
    elsif ($txt =~ m/t/i) {
        $txt =~ s/[^\d.]//g; # Strip all except digits and .
        $txt =~ s/\.+/\./; # Handle many . here but wont catch 3.5.3.5 for example
        $txt = ($txt * 1048576);
        $widget->get_adjustment->set_value($txt);
    }

    return 0;
}

sub spinbox_time_in {
    my ($widget) = @_;
    my $txt = $widget->get_text();

    if ($txt =~ m/ms/i) {
        $txt =~ s/[^\d.]//g; # Strip all except digits and .
        $txt =~ s/\.+/\./; # Handle many . here but wont catch 3.5.3.5 for example
        $widget->get_adjustment->set_value(int($txt));
    }
    elsif ($txt =~ m/sec/i) {
        $txt =~ s/[^\d.]//g; # Strip all except digits and .
        $txt =~ s/\.+/\./; # Handle many . here but wont catch 3.5.3.5 for example
        $txt = ($txt * 1000);
        $widget->get_adjustment->set_value($txt);
    }
    elsif ($txt =~ m/min/) {
        $txt =~ s/[^\d.]//g; # Strip all except digits and .
        $txt =~ s/\.+/\./; # Handle many . here but wont catch 3.5.3.5 for example
        $txt = ($txt * 60000);
        $widget->get_adjustment->set_value($txt);
    }

    return 0;
}

# Adds appropriate units to a spinbox when specifying time
sub spinbox_time_out {
    my ($widget) = @_;
    my $txt = $widget->get_text();
    my $adjustment = $widget->get_adjustment();
    my $adjval = int($adjustment->get_value());

    if ($adjval < 1000) {
        $adjustment->step_increment(1.00);
        $txt = "$adjval ms";
    }
    elsif ($adjval < 60000) {
        $adjustment->step_increment(10.00);
        $adjval /= 1000;
        $txt = sprintf('%0.2f secs', $adjval);
    }
    else {
        $adjustment->step_increment(600.00);
        $adjval /= 60000;
        $txt = sprintf('%0.2f mins', $adjval);
    }

    $widget->set_text($txt);
    return 1;
}

# Adds appropriate units to a spinbox when specifying percent
sub spinbox_pc_out {
    my ($widget) = @_;
    my $adjustment = $widget->get_adjustment();
    my $adjval = int($adjustment->get_value());
    $widget->set_text($adjval . '%');
    return 1;
}

# Handles a percent when specified in a spinbox
sub spinbox_pc_in {
    my ($widget) = @_;
    my $txt = $widget->get_text();

    if ($txt =~ m/\%/) {
        $txt =~ s/[^\d.]//g; # Strip all except digits and .
        $widget->get_adjustment->set_value(int($txt));
    }

    return 0;
}

# Callback set on a timer to attempt to keep the connection alive in the
# case where a timeout is set on the server. This callback needs to be cheap
sub heartbeat {
    IVirtualBox_getVersion($gui{websn}) if ($gui{websn});
    return 1; # Return 1 to stop the timer from being removed
}

sub secs_to_humantime {
    my ($time) = @_;
    my $hours = int($time / 3600);
    $time -= ($hours * 3600);
    my $mins = int($time / 60);
    my $secs = $time % 60;
    $hours = '0' . $hours if ($hours < 10);
    $mins = '0' . $mins if ($mins < 10);
    $secs = '0' . $secs if ($secs < 10);

    return "$hours:$mins:$secs";
}

# Returns truth according to virtualbox which can take the form of
# null, Null, False, false (being 0) and True, true being 1
sub bl { ($_[0] =~ m/^[t|T]/) // return 1 }

# Converts a path to its canonical form
sub rcanonpath {
    my $vhost = &vhost();
    unless ($$vhost{os} =~ m/^WINDOWS/i) { return File::Spec::Unix->canonpath(@_); }
    else { return File::Spec::Win32->canonpath(@_); }
}

# Concatenates a file onto a path
sub rcatfile {
    my $vhost = &vhost();
    unless ($$vhost{os} =~ m/^WINDOWS/i) { return File::Spec::Unix->catfile(@_); }
    else { return File::Spec::Win32->catfile(@_); }
}

# Concatenates a dir onto a path
sub rcatdir {
    my $vhost = &vhost();
    unless ($$vhost{os} =~ m/^WINDOWS/i) { return File::Spec::Unix->catdir(@_); }
    else { return File::Spec::Win32->catdir(@_); }
}

# Splits a path into volume, dir, file
sub rsplitpath {
    my $vhost = &vhost();
    unless ($$vhost{os} =~ m/^WINDOWS/i) { return File::Spec::Unix->splitpath(@_); }
    else { return File::Spec::Win32->splitpath(@_); }
}

1;
