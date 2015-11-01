use Test::More;
use Test::MockObject;
use Test::LWP::UserAgent;
use Data::Dumper;
use WWW::Xunlei;

my $client = WWW::Xunlei->new( 'zshengli@cpan.org', 'matrix' );
ok( defined $client && ref $client eq 'WWW::Xunlei', "WWW::Xunlei Use OK" );

$client->{'ua'} = Test::LWP::UserAgent->new();
$client->{'ua'}->cookie_jar( { ignore_discard => 0 } );
$client->{'ua'}->agent($WWW::Xunlei::DEFAULT_USER_AGENT);

my $check_response = HTTP::Response->new(
    '200', 'OK',
    [   'Content-Type' => 'text/html; charset=utf-8',
        'Set-Cookie'   => 'check_result=0:!fQs; PATH=/; DOMAIN=xunlei.com;',
        'Set-Cookie'   => 'deviceid='
            . 'wdi10.justafakeid;'
            . ' PATH=/; DOMAIN=xunlei.com;EXPIRES=Mon, 27-Oct-25 02:09:57 GMT;',
    ],
    ''
);

$client->{'ua'}->map_response(
    qr{login.xunlei.com/check},
    $check_response,
);


is( $client->_get_verify_code(), '!fQs', '_get_verify_code OK' );

my $form_login_response = HTTP::Response->new(
    '200', 'OK',
    [   'Content-Type' => 'text/html; charset=utf-8',
        'Set-Cookie'   => 'blogresult=0; PATH=/; DOMAIN=xunlei.com;'
            . ' PATH=/; DOMAIN=xunlei.com;EXPIRES=Mon, 27-Oct-25 02:09:57 GMT;',
        'Set-Cookie'   => 'sessionid=justafakesessionid;'
            . ' PATH=/; DOMAIN=xunlei.com;',
        'Set-Cookie'   => 'userid=123456789; PATH=/; DOMAIN=xunlei.com;',
    ],
    '',
);

$client->{'ua'}->map_response(
    qr{login.xunlei.com/sec2login},
    $form_login_response,
);

is ( $client->_form_login, 0, '_form_login OK');

done_testing();
