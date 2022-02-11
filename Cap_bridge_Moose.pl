use v5.20;
use warnings;
use strict;

use Lab::Moose;
use Carp;

use Lab::Moose::Connection::VISA_GPIB;

# measure the time
use Time::HiRes qw/time/;
my $start_time = time();

# Instruments
# ===========

my $YOKO_GATE = instrument(
    type                => 'Yokogawa7651',
    connection_type     => 'VISA_GPIB',
    connection_options  => {
        pad => 5,
    },
    max_units_per_second    => 0.03,
    max_units_per_step      => 0.0005,
    min_units               => -1,
    max_units               => 2,
);

my $AH = instrument(
	type 				=> 'AH2700A',
	connection_type		=> 'VISA_GPIB',
	connection_options	=> {
		pad => 28,
	},
);
$AH->set_field(fi1 => "OFF", fi2 => "OFF", fi3 => 9, fi4 => 9, fi5 => "ON", fi6 => "OFF");
$AH->set_volt( value => 0.05 );
$AH->set_frq( value => 1000);
$AH->set_aver( value => 1 );
$AH->set_bias( value => "ILOW" );

my $isobus = Lab::Moose::Connection::VISA_GPIB->new(pad => 24);

my $IPS = instrument(
	type => 'OI_IPS',
	connection_type => 'IsoBus',
	connection_options => {
		base_connection => $isobus,
		isobus_address => 2
	},
	max_field_rates => [1],
	max_fields => [10],
);
$IPS->hold();
 
my $ITC = instrument(
	type => 'OI_ITC503',
	connection_type => 'IsoBus',
	connection_options => {
		base_connection => $isobus,
		isobus_address => 0
	}
);
$ITC->itc_set_PID_auto(value => 0);
$ITC->itc_set_PID(
	p => 180,
	i => 1,
	d => 0.5
);

my $LAKE = instrument(
    type => 'Lakeshore340',
    connection_type => 'VISA_GPIB',
    connection_options => {
        pad => 12
    }
);

# Data File
# =========

my $file = sweep_datafile(
    filename => 'Cap_Loss_values',
	columns => [qw/
		TIME
		T_VTI
		T_SAMPLE
		B_R
		U_GATE
		FRQ
		CAP
		LOSS
		U_AC
    /],
	comment_string => "COLUMNS#\t"
);
# Plot
# ================

# $file->add_plot(
	# curves => [
		# {x => 'U_GATE', y => 'CAP',  curve_options => {with => 'points', pt => '1', lc "red"}},
		# {x => 'U_GATE', y => 'LOSS', curve_options => {axes => 'x1y2',  with => 'points', pt => '2', lc "green"}},
	# ],
	# plot_options => {
		# title   => 'CAP and LOSS vs U_GATE',
		# format  => {y => "'%.2e'", y2 => "'%.2e'"},
	# },
	# hard_copy => 'cap_loss_vs_u_gate.png'
# );

$file->add_plot(
	curves => [
		{x => 'B_R', y => 'CAP',  curve_options => {with => 'points', pt => '1', linecolor => "red"}},
		{x => 'B_R', y => 'LOSS', curve_options => {axes => 'x1y2',  with => 'points', pt => '2', linecolor => "green"}},
	],
	plot_options => {
		title   => 'CAP and LOSS vs B_R',
		format  => {y => "'%.2e'", y2 => "'%.2e'"},
	},
	hard_copy => 'cap_loss_vs_bfield.png'
);


# Sweeps
# ======

my $magnet_sweep = sweep(
	type       => 'Step::Magnet',
	instrument => $IPS,
	delay_in_loop => 5,
	from => 0.1,
	to   => 0.11, # 0, 0.5, 1, 1.5,
	step => 0.01,
	start_rate => 0.5,
	rate => 0.3,
	backsweep => 0, #0=no backsweep; 1=including backsweep
);

my $gate_sweep = sweep(
	type       => 'Step::Voltage',
	instrument => $YOKO_GATE,
	from => 0,
	to   => 0.2,
	step => 0.1,
	delay_in_loop => 5,
	backsweep => 0,
);

# Measurement
# ===========

my $meas = sub {
    my $sweep = shift;

	my $time = time()-$start_time;
	my $t_vti = $ITC->get_value();
	my $t_sample = $LAKE->get_value(channel => 'A');
	my $b_r = $IPS->get_value();
	my $frq = $AH->get_frq();
    my $u_gate = $YOKO_GATE->get_level();
	my ($c, $l, $v) = $AH->get_value();
		
    $sweep->log(
        TIME => $time,
		T_VTI => $t_vti,
		T_SAMPLE => $t_sample,
		B_R => $b_r,
		FRQ => $frq,
		U_GATE => $u_gate,
		CAP => $c,
		LOSS => $l,
		U_AC => $v,
    );
};

# $magnet_sweep->start(
    # slave       => $gate_sweep,
    # measurement => $meas,
    # datafile    => $file,
# );

$gate_sweep->start(
    slave       => $magnet_sweep,
    measurement => $meas,
    datafile    => $file,
);
