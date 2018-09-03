use Test2::V0;
use Test2::API qw(context);
use Test2::Tools::Spec;
use Test2::Tools::Explain;
use Test2::Plugin::SpecDeclare;
use strictures 2;

use Net::Curl::Parallel::Response;

subtest basics => sub{
  ok my $r = Net::Curl::Parallel::Response->new, 'ctor';
  ok !$r->completed, 'incomplete';

  print {$r->fh_head} "HTTP/1.1 200 OK\r\nContent-type: text/sarcasm\r\nDate: Tue, 12 Dec 2017 08:00:00 GMT\r\n\r\n";
  print {$r->fh_body} 'how now brown bureaucrat';

  ok $r->complete,  'complete';
  ok $r->completed, 'completed';

  is $r->headers, {'content-type' => 'text/sarcasm', 'date' => 'Tue, 12 Dec 2017 08:00:00 GMT'}, 'headers';
  is $r->content, 'how now brown bureaucrat', 'content';

  subtest as_http_response => sub{
    isa_ok((my $h = $r->as_http_response), 'HTTP::Response');
    is $h->content, 'how now brown bureaucrat', 'content';
    is $h->header('Content-type'), 'text/sarcasm', 'header';
  };
};

subtest fail => sub{
  my $r = Net::Curl::Parallel::Response->new;
  $r->fail('fnord');
  ok $r->completed, 'complete';
  is $r->error, 'fnord', 'error';
  is $r->headers, hash{ end; }, 'headers';
};

done_testing;
