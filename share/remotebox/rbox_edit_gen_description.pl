# The Description page of the General Settings
use strict;
use warnings;
our (%gui, %vmc);

sub init_edit_gen_description {
    &busy_pointer($gui{dialogEdit}, 1);
    $gui{textbufferEditGenDescription}->set_text(IMachine_getDescription($vmc{IMachine}));
    &busy_pointer($gui{dialogEdit}, 0);
}

# Sets the guest's description
sub gen_description {
    my $iter_s = $gui{textbufferEditGenDescription}->get_start_iter();
    my $iter_e = $gui{textbufferEditGenDescription}->get_end_iter();
    IMachine_setDescription($vmc{IMachine}, $gui{textbufferEditGenDescription}->get_text($iter_s, $iter_e, 0));
    return 0;
}

1;
