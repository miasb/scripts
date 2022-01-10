use v5.20;
use warnings;
use strict;

use Lab::Measurement;
use Carp;

use Lab::Moose::Connection::VISA_GPIB;

#--------preample---------

#my $vorwiderstand = 100000;
my $ithaco_sens=1E-5; #die sensitivity am Ithaco
my $femto_DC=1000;  #femtos
my $femto_AC=1000;
# my $preamp_ref_ac=10;


#---------device-init----------

# my $YOKO_SD = instrument(
#     type                => 'Yokogawa7651',
#     connection_type     => 'VISA_GPIB',
#     connection_options  => {
#         pad => 7,
#     },
#     max_units_per_second    => 0.05,
#     max_units_per_step      => 0.005,
#     min_units               => -1,
#     max_units               => 1
# );

my $YOKO_GATE = instrument(
    type                => 'Yokogawa7651',
    connection_type     => 'VISA_GPIB',
    connection_options  => {
        pad => 5,
    },
    max_units_per_second    => 0.05,
    max_units_per_step      => 0.005,
    min_units               => -3,
    max_units               => 7
);

# my $Multimeter_I = instrument(      # misst Strom nach dem ithaco
#     type                => 'Agilent34410A',
#     connection_type     => 'VISA_GPIB',
#     connection_options  => {
#         pad => 18
#     }
# );
# $Multimeter_I->sense_nplc(value => 2); # integrationszeit 10x netzfrequenz

my $LOCKIN_AC = instrument(      # misst strom
    type                => 'SignalRecovery7265',
    connection_type     => 'VISA_GPIB',
    connection_options  => {
        pad => 15
    }
);


# my $Multimeter_Sample_xx = instrument(      # misst U_DC_4pt
#     type                => 'Agilent34420A',
#     connection_type     => 'VISA_GPIB',
#     connection_options  => {
#         pad => 16
#     }
# );
# $Multimeter_I->sense_nplc(value => 10); # integrationszeit 10x netzfrequenz


# my $LOCKIN_REF = instrument(      # misst strom
#     type                => 'SignalRecovery7265',
#     connection_type     => 'VISA_GPIB',
#     connection_options  => {
#         pad => 15
#     }
# );

my $LOCKIN_SAMPLE_l = instrument(   
    type                => 'SignalRecovery7265',
    connection_type     => 'VISA_GPIB',
    connection_options  => {
        pad => 10
    } #misst U_AC_4pt_l (4-punkt spannung links)
);

my $LOCKIN_SAMPLE_r = instrument(   
    type                => 'SignalRecovery7265',
    connection_type     => 'VISA_GPIB',
    connection_options  => {
        pad => 14
    } #misst U_AC_4pt_r (4-punkt spannung rechts)
);


# KRYO1STEUERUNG -------------------------------------------------------

 
my $isobus = Lab::Moose::Connection::VISA_GPIB->new(pad => 24);

my $IPS = instrument(
	type => 'OI_IPS',
	connection_type => 'IsoBus',
	connection_options => {
		base_connection => $isobus,
		isobus_address => 2
	},
	max_field_rates => [1],
	max_fields => [9],
);
 
my $ITC = instrument(
	type => 'OI_ITC503',
	connection_type => 'IsoBus',
	connection_options => {
		base_connection => $isobus,
		isobus_address => 0
	}
);

# Für die Temperaturanzeige
my $LAKE = instrument(
    type => 'Lakeshore340',
    connection_type => 'VISA_GPIB',
    connection_options => {
        pad => 12
    }
);


#----------------------------------------------------------

# my $sweep_dc = sweep(
# 	type       => 'Step::Voltage',
# 	instrument => $YOKO_SD,
# 	interval => 2,
# 	points => [1, 0.5], #-0.3, 0.3
# 	steps => [0.05],	
# 	rate => [0.005], #0.005, 0.0004 in V/s
# 	delay_before_loop => 10,
# 	backsweep => 2, #nur in eine richtung backsweep 0; 
# );

my $gate_sweep = sweep(
	type       => 'Step::Voltage',
	instrument => $YOKO_gate,
	delay_before_loop => 5,
	backsweep => 0,
    # step
	#points => [0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0],
	#steps => [1],
	list => [0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0],
    # continuous
	interval => 2,
	rates => [0.04]
);


my $magnet_sweep = sweep(
	type       => 'Continuous::Magnet',
	instrument => $IPS,
	delay_before_loop => 5,
	backsweep => 0,
    
	points => [-0.003, 0.055], #1 flussquant pro Antidot bei 0.005754T
	# step
	steps => [0.0015], 
    # continuous
	interval => 3,
	rates => [0.010, 0.002] #0.05
);

my $temp_sweep = sweep(
    type        => 'Step::Temperature',
    instrument  => $ITC,
    sensor      => $LAKE,

	points  => [3.845, 4.8, 4.75, 4.75, 4.7, 4.7, 4.65, 4.65, 4.6, 4.6], #gap bei ??
	steps   => [0.050],

	observation_time    => 5*60,		
	tolerance_setpoint  => 0.050, #gilt fürs ITC			
	tolerance_std_dev   => 0.025, #gilt fürs ITC				
	sensor_std_dev      => 0.05, #gilt fürs lakeshore
);


#-------------------------------------------------------

my $file = sweep_datafile(
    filename => 'I_V_trace.dat',
	columns => [qw/
                TIME
                T_VTI
                T_SAMPLE
                B
                U_gate
                U_AC
                U_AC_CURRENT
                U_AC_4PT_l
                U_AC_4PT_r
                I_AC
                dR_l
                dR_r
                HE
                /]
        # columns => [qw/ TIME T_VTI T_SAMPLE B U_gate U_AC U_AC_CURRENT U_AC_4PT_l U_AC_4PT_r I_AC dR_l dR_r HE U_DC U_CURRENT I U_DC_4PT_xx R_SAMPLE_xx /]
);

#-------------------------magnetic field plots------------------------

$file->add_plot(
	x => 'B',
	y => 'dR_l',
	plot_options => {
		title   => 'dR_l vs B',
        type    => 'point',
        grid    => 'xtics ytics',
        format  => {x => "'%1.3f'", y => "'%1.2f'"},
	},
	hard_copy => 'dR_l-vs-B.png'
);


$file->add_plot(
	x => 'B',
	y => 'dR_r',
	plot_options => {
		title   => 'dR_r vs B',
        type    => 'point',
        grid    => 'xtics ytics',
        format  => {x => "'%1.3f'", y => "'%1.2f'"},
	},
	hard_copy => 'dR_r-vs-B.png'
);

#---------------------------------current I plots -----------------------------------
# my $plot = {
		# #'autosave' => 'last', # last, allways, never
		# 'title' => 'R_SAMPLE_xy vs I',
		# 'type' => 'point', #'lines', #'linetrace', #point
		# 'x-axis' => 'I',
		# 'x-format' => '%1.2e',
		# #'x-min' => -1,
		# #'x-max' => 1,
		# 'y-axis' => 'R_SAMPLE_xy',
		# 'y-format' => '%1.2f',
		# #'y-min' => -1,
		# #'y-max' => 1,
		# 'grid' => 'xtics ytics',		
		# };
# $file->add_plot($plot);

# my $plot2 = {
		# #'autosave' => 'last', # last, allways, never
		# 'title' => 'dR_xy vs I',
		# 'type' => 'point', #'lines', #'linetrace', #point
		# 'x-axis' => 'I',
		# #'x-min' => -1,
		# #'x-max' => 1,
		# 'y-axis' => 'dR_xy',
		# 'y-format' => '%1.2e',
		# #'y-min' => -1,
		# #'y-max' => 1,
		# # 'cb-axis' => 'U_DC_4PT',
		# 'grid' => 'xtics ytics',		
		# };
# $file->add_plot($plot2);

# my $plot3 = {
		# #'autosave' => 'last', # last, allways, never
		# 'title' => 'R_SAMPLE_xx vs I',
		# 'type' => 'point', #'lines', #'linetrace', #point
		# 'x-axis' => 'I',
		# 'x-format' => '%1.2e',
		# #'x-min' => -1,
		# #'x-max' => 1,
		# 'y-axis' => 'R_SAMPLE_xx',
		# 'y-format' => '%1.2f',
		# #'y-min' => -1,
		# #'y-max' => 1,
		# 'grid' => 'xtics ytics',		
		# };
# $file->add_plot($plot3);

# my $plot4 = {
		# #'autosave' => 'last', # last, allways, never
		# 'title' => 'dR_xx vs I',
		# 'type' => 'point', #'lines', #'linetrace', #point
		# 'x-axis' => 'I',
		# #'x-min' => -1,
		# #'x-max' => 1,
		# 'y-axis' => 'dR_xx',
		# 'y-format' => '%1.2e',
		# #'y-min' => -1,
		# #'y-max' => 1,
		# # 'cb-axis' => 'U_DC_4PT',
		# 'grid' => 'xtics ytics',		
		# };
# $file->add_plot($plot4);


#-----------------------------------------------------
$file->add_plot(
	x => 'TIME',
	y => 'T_SAMPLE',
	plot_options => {
		title   => 'T_SAMPLE vs TIME',
	},
	hard_copy => 'T_SAMPLE-vs-TIME.png'
);

$file->add_plot(
	x => 'TIME',
	y => 'HE',
	plot_options => {
		title   => 'HE vs TIME',
	},
	hard_copy => 'HE-vs-TIME.png'
);


#-------------------------------------------------------------



my $measurement = sub {

	my $sweep = shift;
	my $time = $sweep->{Time};
	
	my $he_level = $IPS->get_level();
	
	my $U_gate = $YOKO_gate->get_level(); #topgate voltage
	my $t_sample = $lake->get_value(channel =>'B');
	my $t_vti = $ITC->get_value(1);
	
	my $b =$IPS->get_value();



	# my $u_DC = $YOKO_SD->get_level();			# U I R R
	# my $U_DC_current = $Multimeter_I->get_value();
		


	# my $U_DC_4pt_xx = $Multimeter_Sample_xx->get_value(1);
	# my $U_DC_4pt_xx = $U_DC_4pt_xx / $femto_DC;
	
	# my $I_DC=$U_DC_current * $ithaco_sens;
	
	# my $r_sample_xx = ($I_DC != 0) ? ($U_DC_4pt_xx / $I_DC) : '?';
	
	my $u_AC = $LOCKIN_AC->cached_source_level();
	
	my $u_AC_CURRENT = $LOCKIN_AC->get_value(channel => 'X');
	# my $u_AC_ref =  $u_AC_ref_1 / $preamp_ref_ac;
	 
	
	
	my $U_AC_4pt_l = $LOCKIN_SAMPLE_l->get_value(channel => 'X');
	my $U_AC_4pt_l = $U_AC_4pt_l / $femto_AC;
	
	my $U_AC_4pt_r = $LOCKIN_SAMPLE_r->get_value(channel => 'X');
	my $U_AC_4pt_r = $U_AC_4pt_r / $femto_AC;
	
	my $i_AC = $u_AC_CURRENT*$ithaco_sens;
	
	my $dR_l = ($i_AC != 0) ? ($U_AC_4pt_l / $i_AC) : '?';
	my $dR_r = ($i_AC != 0) ? ($U_AC_4pt_r / $i_AC) : '?';

	

	
	$sweep->LOG({
	
		TIME => $time,
		T_VTI => $t_vti,
		T_SAMPLE => $t_sample,
		
		HE => $he_level,
		
		B => $b,
		U_gate => $U_gate,
		# U_DC => $u_DC,
		# U_CURRENT => $U_DC_current,

		# U_DC_4PT_xx=> $U_DC_4pt_xx,
		# I => $I_DC,

		# R_SAMPLE_xx => $r_sample_xx,
		U_AC => $u_AC,
		U_AC_CURRENT => $u_AC_CURRENT,

		U_AC_4PT_l => $U_AC_4pt_l,
		U_AC_4PT_r => $U_AC_4pt_r,
		I_AC => $i_AC,
	
		dR_l => $dR_l,
		dR_r => $dR_r,	
	});
	
};

#-------- 5. Helium level control -------

# my $check_helium = sub {
# 	my $he_level = $IPS->get_level();
# 	print "\n\n\nHelium check: Level = $he_level ... ";
# 	if ($he_level <= 8) {
# 		print "\n\nLow Helium Level! Sweep to zero and enable persistent mode \n";
# 		$IPS->sweep_to_level(0);
# 		print "Pause... Press Enter to proceed\n";
# 		ReadMode('normal');
# 		<>;
# 		ReadMode('cbreak');
# 	}
# 	else {
# 		print "OK \n\n\n";
# 	}
# };


#-----------------------------------------------------------------------------

$gate_sweep->start(
    slave       => $magnet_sweep,
    measurement => $measurement,
    datafile    => $file
);




# $YOKO_SD->config_sweep(0, 0.01);
# $YOKO_SD->trg();
# $YOKO_SD->wait();

# $ITC->set_T(60);

# $IPS->config_sweep(0.000, 0.100); # T/min
 # $IPS->trg();
 # $IPS->wait();
