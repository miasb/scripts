use Lab::Moose;

my $isobus = Lab::Moose::Connection::VISA_GPIB->new(pad => 24);

my $IPS = instrument(
    type            => 'OI_IPS',
    connection_type => 'IsoBus',
    connection_options => {
        base_connection => $isobus,
        isobus_address  => 2
    },
    max_field_rates => [1],
    max_fields      => [9],
);

my $magnet_sweep = sweep(
    type       => 'Continuous::Magnet',
    instrument => $IPS,
    intervals  => [4],

	points => [1, -0.8, 0.7, -0.6, 0.5, -0.4, 0.3, -0.2, 0.1, -0.05, 0.025, -0.015, 0.005, -0.004, 0.003, -0.002, 0.001, -0.0005, 0.0005, 0],
	rates  => [0.5, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.1, 0.1, 0.05, 0.05, 0.05, 0.005, 0.005, 0.005, 0.001, 0.001, 0.001],

    delay_before_loop => 0,
    backsweep         => 0,
);

my $file = sweep_datafile(
    filename = 'remove_me.dat',
    columns  = [qw/help/]
);

my $meas = sub {
    my $sweep = shift;
};

$magnet_sweep->start(
    measurement => $meas,
    datafile    => $file
);
