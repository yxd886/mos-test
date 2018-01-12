#!/usr/bin/env perl
#
# combinations we have to test:
# plain 404 case
# 404-handler -> static file (verify content)
# 404-handler -> fastcgi
#   returning 200
#   returning 302 + Location
#   returning 404
#   returning no status -> 200
#
BEGIN {
	# add current source dir to the include-path
	# we need this for make distcheck
	(my $srcdir = $0) =~ s,/[^/]+$,/,;
	unshift @INC, $srcdir;
}

use strict;
use IO::Socket;
use Test::More tests => 8;
use LightyTest;

my $tf = LightyTest->new();
my $t;
$tf->{CONFIGFILE} = '404-handler.conf';

ok($tf->start_proc == 0, "Starting lighttpd") or die();

$t->{REQUEST}  = ( <<EOF
GET /static/notfound HTTP/1.0
EOF
 );
$t->{RESPONSE} = [ { 'HTTP-Protocol' => 'HTTP/1.0', 'HTTP-Status' => 200, 'HTTP-Content' => "static not found\n" } ];
ok($tf->handle_http($t) == 0, '404 handler => static');

#
#
#
$t->{REQUEST}  = ( <<EOF
GET /dynamic/200/notfound HTTP/1.0
EOF
 );
$t->{RESPONSE} = [ { 'HTTP-Protocol' => 'HTTP/1.0', 'HTTP-Status' => 200, 'HTTP-Content' => "found here\n" } ];
ok($tf->handle_http($t) == 0, '404 handler => dynamic(200)');

$t->{REQUEST}  = ( <<EOF
GET /dynamic/302/notfound HTTP/1.0
EOF
 );
$t->{RESPONSE} = [ { 'HTTP-Protocol' => 'HTTP/1.0', 'HTTP-Status' => 302, 'Location' => "http://www.example.org/" } ];
ok($tf->handle_http($t) == 0, '404 handler => dynamic(302)');

$t->{REQUEST}  = ( <<EOF
GET /dynamic/404/notfound HTTP/1.0
EOF
 );
$t->{RESPONSE} = [ { 'HTTP-Protocol' => 'HTTP/1.0', 'HTTP-Status' => 404, 'HTTP-Content' => "Not found here\n" } ];
ok($tf->handle_http($t) == 0, '404 handler => dynamic(404)');

$t->{REQUEST}  = ( <<EOF
GET /dynamic/nostatus/notfound HTTP/1.0
EOF
 );
$t->{RESPONSE} = [ { 'HTTP-Protocol' => 'HTTP/1.0', 'HTTP-Status' => 200, 'HTTP-Content' => "found here\n" } ];
ok($tf->handle_http($t) == 0, '404 handler => dynamic(nostatus)');

$t->{REQUEST}  = ( <<EOF
GET /send404.pl HTTP/1.0
EOF
 );
$t->{RESPONSE} = [ { 'HTTP-Protocol' => 'HTTP/1.0', 'HTTP-Status' => 404, 'HTTP-Content' => "send404\n" } ];
ok($tf->handle_http($t) == 0, '404 generated by CGI should stay 404');

ok($tf->stop_proc == 0, "Stopping lighttpd");

