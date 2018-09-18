# NAME

Net::Curl::Parallel - perform concurrent HTTP requests using libcurl

# SYNOPSIS

    use Net::Curl::Parallel;

    my $fetch = Net::Curl::Parallel->new(
      agent           => 'Net::Curl::Parallel/v0.1',
      slots           => 10,
      max_redirects   => 3,
      connect_timeout => 50,  # ms
      request_timeout => 500, # ms
    );

    # Add requests to be handled concurrently
    my ($req1) = $fetch->add(HTTP::Request->new(...));         # pass an HTTP::Request instance
    my ($req2) = $fetch->add(GET => 'http://www.example.com'); # pass HTTP::Request constructor args
    my ($req3) = $fetch->try(GET => ...);                      # like add() but don't croak on failure

    # Request the... uh, well, requests
    $fetch->perform;

    # Collect individually
    my $res1 = $fetch->collect($req1);
    my $res2 = $fetch->collect($req2);
    my $res3 = $fetch->collect($req3);

    # Collect a few
    my @responses = $fetch->collect($req1, $req2);

    # Or get the whole set
    my @responses = $fetch->collect;

    # Perform a single request
    my $response = Net::Curl::Parallel->fetch(...);

# DESCRIPTION

    Stop trying to make fetch happen; it's not going to happen
      <https://www.youtube.com/watch?v=Pubd-spHN-0>
      -- author of superior module, L<ZR::Curl>, fREW "mean-girl" Schmidt

# CLASS METHODS

## fetch

Performs a single request and returns the response. Accepts the same parameters
as ["add"](#add) or ["try"](#try) and returns a [Net::Curl::Parallel::Response](https://metacpan.org/pod/Net::Curl::Parallel::Response). Internally, this routine
uses ["try"](#try), so failed requests do not `die`. Instead, check the value of
["failed" in Net::Curl::Parallel::Response](https://metacpan.org/pod/Net::Curl::Parallel::Response#failed).

    my $response = Net::Curl::Parallel->fetch(GET => ...);

    if ($response->failed) {
      ...
    } else {
      ...
    }

## max\_curls\_in\_pool

Please see the NOTES below about this class method.

# METHODS

## new

The default values for constructor arguments have been selected as sensible for
an interactive web request. Please exercise care when increasing these numbers
to ensure web service worker availability as well as to avoid bandwidth
saturation and throttling.

- agent

    User agent string. Defaults to `'Net::Curl::Parallel/v0.1'`.

- slots

    Max number of requests to process simultaneously. Defaults to 10.

- max\_redirects

    Max number of times a remote server may redirect any single request. Defaults
    to `undef` (no redirects).

- connect\_timeout

    Max initial connection time in milliseconds. Defaults to 50.

- request\_timeout

    Max total request time in milliseconds. Defaults to 500.

- keep\_alive

    Autmatically set `Connection: keep-alive` on all HTTP requests. Defaults to
    true.

    If a request already has a `Connection:` header, that header will be left alone.

- verbose

    Turn on verbose logging within curl. Defaults to false.

## add

Adds any number of [HTTP::Request](https://metacpan.org/pod/HTTP::Request) objects to the download set. May also be
called with arguments to pass unchanged to the [HTTP::Request](https://metacpan.org/pod/HTTP::Request) constructor, in
which case all arguments are consumed and a single request is added.

Any request which fails will croak, preventing the servicing of any further
requests. Completed requests result in an [Net::Curl::Parallel::Response](https://metacpan.org/pod/Net::Curl::Parallel::Response) object.

Returns a list of array indexes that identify the location of the responses in
the result array returned by ["perform"](#perform). The order of the returned indexes
corresponds to the order of requests passed to `add` as parameters.

    my @ids  = $fetch->add($req1, $req2, $req3);
    my ($id) = $fetch->add(GET => ...);

    # This also works.
    my $id   = $fetch->add(GET => ...);

## try

Similar to ["add"](#add), but a failed request will result in a failed
[HTTP::Response](https://metacpan.org/pod/HTTP::Response) with an error message rather than croaking.

    $fetch->try(HTTP::Request->new(...));

    my ($response) = $fetch->perform;

    if ($response->failed) {
      handle_errors($response->error);
    } else {
      do_stuff($response);
    }

## perform

Performs all requests and returns a list of each response in the order it was
added. This method will not return until all requests have completed or an
unhandled error is encountered. Returns a list of [Net::Curl::Parallel::Response](https://metacpan.org/pod/Net::Curl::Parallel::Response)
objects corresponding to the index values returned by the ["add"](#add) and ["try"](#try)
methods.

The behavior of an individual request when an error is encountered (e.g. unable
to reach the remote host, timeout, etc.) is determined by whether the request
was added by ["add"](#add) or ["try"](#try).

**NOTE**: This means perform() could end prematurely if a request added with ["add"](#add) throws an exception, even if all the other requests were added with ["try"](#try).

## collect

When called in list context, returns a list of responses corresponding to the
list of request ids passed in. If called without arguments, the defaults to all
responses.

When called in scalar context, returns a single response corresponding to the
request id passed in. If called without arguments, returns an array ref holding
all responses.

**NOTE**: This will **not** block if the request is not completed with ["perform"](#perform).

# NOTES

## POSTs and Expect header

If you ["add"](#add) a POST request, libcurl normally adds a 'Expect: 100-continue'
header depending on the body size. This can often result in undesirable
behavior, so Net::Curl::Parallel disables that by adding a blank 'Expect:'
header by default.

You can set an 'Expect:' header and Net::Curl::Parallel will leave it alone.

## Pool of curls

In order to conserve memory, there is a process-global pool of Net::Curl::Easy
objects. These are the objects that do the actual HTTP requests. You can access
them with `$self->curls`.

The pool's size defaults to 50. You can set this by calling

    # Or whatever number
    Net::Curl::Parallel->max_curls_in_pool(20);

The pool will be resized the next time ["perform"](#perform) completes.

Note: The pool's max size is ignored while ["perform"](#perform) is running; the max is
only enforced at the end of ["perform"](#perform).

# CAVEATS

## Remember to call perform

    jp    [4:07 PM] ah, helps if you actually `perform` the requests
    jober [4:09 PM] Ah, good caveat. I ought to put that in the docs.
    jp    [4:09 PM] it is in there, just a little hidden

# MAINTAINER

Rob Kinyon <rob.kinyon@gmail.com>

# SUPPORT

Initial versions written by ZipRecruiter staff (jober and others).

Codebase and support generously provided by ZipRecruiter for opensourcing.

# COPYRIGHT & LICENSE

Copyright (C) 2010-onwards by ZipRecruiter

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
