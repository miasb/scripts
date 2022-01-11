use Lab::Measurement;

my $isobus = Connection('VISA_GPIB', {
	gpib_address => 24});
	
my $IPS = Instrument('IPS', {
	connection => Connection('IsoBus', {
		base_connection => $isobus,
		isobus_address => 2})
 });

my $sweep_magnet = Sweep('Magnet', {
	instrument => $IPS,	
	interval => 4,													# measuring intveral in [s]
	
	mode => 'continuous',											# modes: step, continuous, 
	points => [1, -0.8, 0.7, -0.6, 0.5, -0.4, 0.3, -0.2, 0.1, -0.05, 0.025, -0.015, 0.005, -0.004, 0.003, -0.002, 0.001, -0.0005, 0.0005, 0],
	rate => [0.5, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.1, 0.1, 0.05, 0.05, 0.05, 0.005, 0.005, 0.005, 0.001, 0.001, 0.001],
	
	delay_before_loop => 0,
	backsweep => 0,													# 0: Bsweep/gate_step/.. ; 1: Bsweep/B_backsweep/gate_step/..  ; 2: Bsweep/gate_step/B_backsweep/..
});


$sweep_magnet->start();
