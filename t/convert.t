use strict;
use warnings;

use JSON::XS;

use Test::More;
use Test::MockModule;

use Net::FreeIPA;


my $f = Net::FreeIPA->new();

my $data = {
    int => 5,
    float => 10.5,
    string => "a string",
    boolean_false => 0,
    boolean_true => 1,
    not_a_type => {a => 1},
};

my $new_data = {};
foreach my $key (keys %$data) {
    my $type = $key;
    $type =~ s/_\w+$//;
    $new_data->{$key} = $f->convert($data->{$key}, $type);
};

# Convertit in to non-pretty JSON string
my $j = JSON::XS->new();
$j->canonical(1); # sort the keys, to create reproducable results
is($j->encode($new_data),
   '{"boolean_false":false,"boolean_true":true,"float":10.5,"int":5,"not_a_type":{"a":1},"string":"a string"}',
   "JSON string of converted data");

my $mockrpc = Test::MockModule->new("Net::FreeIPA::RPC");

my $args = [];
my $opts = {};
my $command;
my $expected_args = 0;
$mockrpc->mock('rpc', sub {
    my($self, $command, $args, $opts) = @_;
    return $command.$j->encode($args).$j->encode($opts);
});

is($f->rpc_api('do_something',
               [1, 2.5], [qw(boolean float)],
               {false => 0, int => 1, string => 'a string'},
               {false => 'boolean', int => 'int', string => 'string'}),
   'do_something[true,2.5]{"false":false,"int":1,"string":"a string"}',
   "rpc_api converts and calls rpc method as expected");

done_testing();