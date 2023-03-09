use Lab::Moose;

my $source1 = instrument(
    type => 'DummySource',
    connection_type => 'Debug',
    connection_options => {verbose => 0},
    # mandatory protection settings
    max_units_per_step => 0.1, # max step is 1mV/1mA
    max_units_per_second => 1,
    min_units => -10,
    max_units => 10,
);

my $source2 = instrument(
    type => 'DummySource',
    connection_type => 'Debug',
    connection_options => {verbose => 0},
    # mandatory protection settings
    max_units_per_step => 0.1, # max step is 1mV/1mA
    max_units_per_second => 1,
    min_units => -10,
    max_units => 10,
);

my $sweep1 = sweep(
    type => 'Step::Voltage',
    instrument => $source1,
    from => 0, to => 2, step => 0.1,
    both_directions => 1,
);

my $sweep2 = sweep(
    type => 'Continuous::Voltage',
    instrument => $source2,
    from => 0, to=> 1,
    rate => 0.1, interval => 0.1,
);

my $datafile = sweep_datafile(columns => [qw/source1 source2/]);

my $meas = sub {
    my $sweep = shift;
    my $v_gate = $source1->cached_level();
    my $v_bias = $source2->cached_level();
    $sweep->log(
        source1    => $v_gate,
        source2    => $v_bias,
    );
};
 
$sweep2->start(
    slave => $sweep1,
    measurement => $meas,
    datafile => $datafile,
);

