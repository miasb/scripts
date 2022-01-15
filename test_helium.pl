use v5.20;
use warnings;
use strict;
use Lab::Moose;
use Carp;



# HELIUM
# ======
# The get_xxx methods pass a number to the read_parameter method, which in return
# calls 
# my $result = $self->query( command => "R$value\r", %args );
# This is a legacy interface for the iPS. To address the level meter sensor it is
# necessary to use the SCPI command structure:
# DEV:<UID>:LVL
# <UID> is a unique identifier for each board which can be read by 
# READ:SYS:CAT?
# returning something like AUX:DEV:DB4 :LVL for the level meter sensor
# the UID would be DB4 in this case.
# The level can then be read using
# READ:DEV:DB4 :LVL:HEL:LEV?
# The SCPI driver for all Oxford Instruments Mercury magnet power supplies is
# Lab::Moose::Instrument::OI_Mercury::Magnet
# my $IPS = instrument(
#     type => 'OI_Mercury::Magnet',

# Devices
my $ips = instrument(
	type => 'OI_Mercury::Magnet',
	connection_type => 'Socket',
	connection_options => {
		host => 'ip',
	},
	magnet => 'Z',  # X, Y or Z. Z is default.
);

# returns the hardware configuration of the iPS
# ... get the level sensors UID

my $sensors = $ips->get_catalogue();

# Set to HOLD
# ===========
# The iPS can be set to hold by calling oim_set_activity()
# The possible values are:
# - HOLD    hold current
# - RTOS    ramp to set point
# - RTOZ    rampt to zero
# - CLMP    clamp output if current is zero

$ips->oim_set_activity(value => 'HOLD');



