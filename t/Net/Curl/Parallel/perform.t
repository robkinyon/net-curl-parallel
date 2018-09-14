use Test2::V0;
use Test2::API qw(context);
use Test2::Tools::Spec;
use Test2::Tools::Explain;
use Test2::Plugin::SpecDeclare;
use strictures 2;

use HTTP::Request;
use Types::Standard -types;
use Net::Curl::Parallel;

use Net::Curl::Easy qw(:constants);
use Net::Curl::Multi qw(:constants);

use Test::MockModule;
use DDP;

my $easy = Test::MockModule->new('Net::Curl::Easy');
$easy->mock(setopt => sub {
  my $self = shift;
  my ($opt, @args) = @_;

  $self->{opts} //= {};
  $self->{opts}{$opt} = [@args];

  return 1;
});

my $multi = Test::MockModule->new('Net::Curl::Multi');
$multi->mock(add_handle => sub {
  my $self = shift;
  $self->{called}{add_handle}++;
});
$multi->mock(wait => sub {
  my $self = shift;
  $self->{called}{wait}++;
});
$multi->mock(perform => sub {
  my $self = shift;
  $self->{called}{perform}++;
});
$multi->mock(info_read => sub {
  my $self = shift;
  $self->{called}{info_read}++;
});
$multi->mock(remove_handle => sub {
  my $self = shift;
  $self->{called}{remove_handle}++;
});

subtest 'perform with no requests' => sub {
  my $f = Net::Curl::Parallel->new;

  my @responses = $f->perform;
  is [@responses], [], 'empty perform does no responses';

  is $f->curl_multi->{called}{add_handle}, undef, 'add_handle never called';
};

done_testing;
