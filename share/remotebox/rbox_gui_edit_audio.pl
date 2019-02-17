# Edit Audio Settings of a Guest
use strict;
use warnings;
our (%gui, %signal, %vmc);

# Initialise the audio page
sub setup_edit_dialog_audio {
    my $vhost = &vhost();
    &addrow_log("Fetching audio settings for $vmc{Name}...");
    &busy_pointer($gui{dialogEdit}, 1);
    $gui{comboboxEditAudioDriver}->signal_handler_block($signal{audiodrv});
    $gui{comboboxEditAudioCtr}->signal_handler_block($signal{audioctr});
    $gui{comboboxEditAudioCodec}->signal_handler_block($signal{audiocodec});
    $gui{checkbuttonEditAudioEnable}->set_active(&bl(IAudioAdapter_getEnabled($vmc{IAudioAdapter})));
    $gui{tableEditAudio}->set_sensitive($gui{checkbuttonEditAudioEnable}->get_active()); # Ghost/Unghost other widgets based on audio enabled

    # Enabling/Disabling Audio Inputs & Outputs seems broken in the API (test: 5.0.20)
    #$gui{checkbuttonEditAudioIn}->set_active(&bl(IAudioAdapter_getEnabledIn($vmc{IAudioAdapter})));
    #$gui{checkbuttonEditAudioOut}->set_active(&bl(IAudioAdapter_getEnabledOut($vmc{IAudioAdapter})));

    # Set WinMM and MMPM to Null as they no longer seem supported and cause problems if set.
    my $AudioDriver = IAudioAdapter_getAudioDriver($vmc{IAudioAdapter});
    IAudioAdapter_setAudioDriver($vmc{IAudioAdapter}, 'Null') if ($AudioDriver eq 'WinMM' or $AudioDriver eq 'MMPM');

    if ($$vhost{os} =~ m/Linux/i) { $gui{comboboxEditAudioDriver}->set_model($gui{liststoreEditAudioDriverLin}); }
    elsif ($$vhost{os} =~ m/Windows/i) { $gui{comboboxEditAudioDriver}->set_model($gui{liststoreEditAudioDriverWin}); }
    elsif ($$vhost{os} =~ m/SunOS/i) { $gui{comboboxEditAudioDriver}->set_model($gui{liststoreEditAudioDriverSol}); }
    elsif ($$vhost{os} =~ m/Darwin/i) { $gui{comboboxEditAudioDriver}->set_model($gui{liststoreEditAudioDriverMac}); }
    else { $gui{comboboxEditAudioDriver}->set_model($gui{liststoreEditAudioDriverOther}); }

    my $controller =  IAudioAdapter_getAudioController($vmc{IAudioAdapter});
    $gui{comboboxEditAudioCodec}->set_model($gui{'liststoreEditAudioCodec' . $controller});
    &combobox_set_active_text($gui{comboboxEditAudioCodec}, IAudioAdapter_getAudioCodec($vmc{IAudioAdapter}));
    &combobox_set_active_text($gui{comboboxEditAudioDriver}, IAudioAdapter_getAudioDriver($vmc{IAudioAdapter}));
    &combobox_set_active_text($gui{comboboxEditAudioCtr}, $controller);
    $gui{comboboxEditAudioDriver}->signal_handler_unblock($signal{audiodrv});
    $gui{comboboxEditAudioCtr}->signal_handler_unblock($signal{audioctr});
    $gui{comboboxEditAudioCodec}->signal_handler_unblock($signal{audiocodec});
    &busy_pointer($gui{dialogEdit}, 0);
    &addrow_log('Audio settings completed.');
}

# Toggle whether audio is enable or not for this guest
sub audio_toggle {
    if ($vmc{SessionType} eq 'WriteLock') {
        my $state = $gui{checkbuttonEditAudioEnable}->get_active();
        IAudioAdapter_setEnabled($vmc{IAudioAdapter}, $state);
        $gui{tableEditAudio}->set_sensitive($state);
    }
}

# Enabling/Disabling Audio Inputs & Outputs seems broken in the API (test: 5.0.20)
# Toggle whether audio inputs are enabled
#sub audio_input_toggle {
#    if ($vmc{SessionType} eq 'WriteLock') {
#        my $state = $gui{checkbuttonEditAudioIn}->get_active();
#        IAudioAdapter_setEnabledIn($vmc{IAudioAdapter}, $state);
#    }
#}

# Enabling/Disabling Audio Inputs & Outputs seems broken in the API (test: 5.0.20)
# Toggle whether audio outputs are enabled
#sub audio_output_toggle {
#    if ($vmc{SessionType} eq 'WriteLock') {
#        my $state = $gui{checkbuttonEditAudioOut}->get_active();
#        IAudioAdapter_setEnabledOut($vmc{IAudioAdapter}, $state);
#    }
#}

# Set the audio controller type
sub audio_ctr {
    if ($vmc{SessionType} eq 'WriteLock') {
        my $controller = &getsel_combo($gui{comboboxEditAudioCtr}, 0);
        IAudioAdapter_setAudioController($vmc{IAudioAdapter}, $controller);
        $gui{comboboxEditAudioCodec}->set_model($gui{'liststoreEditAudioCodec' . $controller});
        &combobox_set_active_text($gui{comboboxEditAudioCodec}, IAudioAdapter_getAudioCodec($vmc{IAudioAdapter}));
    }
}

# Set the audio codec
sub audio_codec {
    if ($vmc{SessionType} eq 'WriteLock') {
        my $codec = &getsel_combo($gui{comboboxEditAudioCodec}, 0);
        IAudioAdapter_setAudioCodec($vmc{IAudioAdapter}, $codec);
    }
}


# Set the audio driver type
sub audio_driver {
    if ($vmc{SessionType} eq 'WriteLock') {
        my $driver = &getsel_combo($gui{comboboxEditAudioDriver}, 0);
        IAudioAdapter_setAudioDriver($vmc{IAudioAdapter}, $driver);
    }
}

1;
