use Test2::V0;
use Test2::API qw(context);
use Test2::Tools::Spec;
use Test2::Tools::Explain;
use Test2::Plugin::SpecDeclare;
use strictures 2;

use HTTP::Request;
use Types::Standard -types;
use Net::Curl::Parallel;

ok my $fetch = Net::Curl::Parallel->new(slots => 2, connect_timeout => 1000, request_timeout => 2000), 'new';
is [$fetch->add(HTTP::Request->new(GET => 'http://www.example.com'), HTTP::Request->new(GET => 'http://www.example.com'))], [0, 1], 'add HTTP::Request';
is [$fetch->add(GET => 'http://www.example.com')], [2], 'add HTTP::Request args';
is [$fetch->try(GET => 'http://www.example.ihopethisneverbecomesarealtldorthistestwillbreak')], [3], 'try';
is scalar @{$fetch->requests}, 4, 'request count';
is scalar @{$fetch->responses}, 0, 'response count';

SKIP: {
  skip 'Network tests disabled; enable them with NET_CURL_PARALLEL_NETWORK_TESTS=1', 1
    unless $ENV{NET_CURL_PARALLEL_NETWORK_TESTS};

  subtest 'perform' => sub{
    is $fetch->perform, 4, 'perform';
    is scalar @{$fetch->responses}, 4, 'response count';

    my $expected_responses = array{
      item validator(sub{ isa_ok($_, 'Net::Curl::Parallel::Response') && !$_->failed });
      item validator(sub{ isa_ok($_, 'Net::Curl::Parallel::Response') && !$_->failed });
      item validator(sub{ isa_ok($_, 'Net::Curl::Parallel::Response') && !$_->failed });
      item validator(sub{ isa_ok($_, 'Net::Curl::Parallel::Response') &&  $_->failed });
    };

    my $responses = $fetch->collect;
    is $responses, $expected_responses, 'collect array';
    is [$fetch->collect], $expected_responses, 'collect list';

    my $res = $fetch->collect(0);
    isa_ok $res, 'Net::Curl::Parallel::Response';
  };

  subtest 'fetch' => sub{
    ok my $res = Net::Curl::Parallel->fetch(GET => 'http://www.example.com'), 'fetch';
    isa_ok $res, 'Net::Curl::Parallel::Response';
  };
};

# subtests:
# CLASS:
# * fetch()
# OBJ:
# * add() / try()
#   * _queue()
#     * request()
# * perform()
# * collect()
# PRIV:
# * setup_curl()
# * set_response()

# request:
# * keep_alive=0 --> Don't add header
# * keep_alive=1, no Connection: in headers --> Add header
# * keep_alive=1, Connection: in headers --> Don't add header
# * method=POST, no Expect: in headers --> Add header
# * method=POST, Expect: in headers --> Don't add header
#
# setup_curl:
# * connect_timeout true --> set CURLOPT_CONNECTTIMEOUT_MS
# * &CURLOPT_TCP_KEEPALIVE --> set CURLOPT_TCP_KEEPALIVE=1
# * verbose=1 --> set CURLOPT_VERBOSE=1
# * method=POST --> CURLOPT_POST=1, CURLOPT_POSTFIELDS=$content
# * @$headers --> set CURLOPT_HTTPHEADER
# * no @$headers --> don't set CURLOPT_HTTPHEADER
# * request_timeout true --> set CURLOPT_TIMEOUT_MS
#
# perform:
# * if no $msg after info_read()
# * if $curl->{private}{die}
#
# collect:
# * pass in one id
# * pass in multiple ids
# * pass in no ids
#
# fetch:
# * call as classmethod
# * call as objectmethod
#   * Creates a new object to work against
#   * Verify by calling on a used object

done_testing;
