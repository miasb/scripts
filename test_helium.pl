use v5.20;
use warnings;
use strict;
use Lab::Moose;
use Carp;
use Lab::Moose::Connection::VISA_GPIB;


# Devices
my $isobus = Lab::Moose::Connection::VISA_GPIB->new(pad => 24);
my $ips = instrument(
	type => 'OI_IPS',
	connection_type => 'IsoBus',
	connection_options => {
		base_connection => $isobus,
		isobus_address => 2
	},
	max_field_rates => [1],
	max_fields => [9],
);

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

my $uids = $ips->query( command => "READ:SYS:CAT?");


# Set to HOLD
# ===========
# The iPS can be set to hold by calling set_activity(0)
# How to set to HOLD when scripts are terminated manually?

