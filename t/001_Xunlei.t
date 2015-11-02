use Test::More;
use Test::MockObject;
use Test::LWP::UserAgent;
use File::Temp qw/tempfile tempdir/;
use File::Spec::Functions;
use WWW::Xunlei;

my $tempdir = tempdir( CLEANUP => 1 );
my $cookie_file = catfile( $tempdir, 'mkpath', 'cookies.txt' );
my $client = WWW::Xunlei->new( 'zshengli@cpan.org', 'matrix',
    cookie_file => $cookie_file );
ok( defined $client && ref $client eq 'WWW::Xunlei' );

$client->{'ua'} = Test::LWP::UserAgent->new();
$client->{'ua'}->cookie_jar( { file => $cookie_file } );
$client->{'ua'}->agent($WWW::Xunlei::DEFAULT_USER_AGENT);

is_deeply(
    $client->_set_cookie( 'foo', 'bar', 604800 ),
    [ 0, 'bar', undef, undef, undef, time() + 604800 ]
);
is( $client->_get_cookie('foo'),        'bar' );
is( $client->_get_cookie('not_exists'), undef );
ok( $client->_delete_cookie('foo') );
ok( $client->_delete_cookie('not_exists') );
#note "cookie file path : $cookie_file";
ok( $client->_save_cookie() );
#note "delete temp cookie file.";
unlink($cookie_file);

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

$client->{'ua'}->map_response( qr{login.xunlei.com/check}, $check_response, );

is( $client->_get_verify_code(), '!fQs', 'get verify code' );

my $form_login_response = HTTP::Response->new(
    '200', 'OK',
    [   'Content-Type' => 'text/html; charset=utf-8',
        'Set-Cookie'   => 'blogresult=0; PATH=/; DOMAIN=xunlei.com;'
            . ' PATH=/; DOMAIN=xunlei.com;EXPIRES=Mon, 27-Oct-25 02:09:57 GMT;',
        'Set-Cookie' => 'sessionid=justafakesessionid;'
            . ' PATH=/; DOMAIN=xunlei.com;',
        'Set-Cookie' => 'userid=123456789; PATH=/; DOMAIN=xunlei.com;',
    ],
    '',
);

$client->{'ua'}
    ->map_response( qr{login.xunlei.com/sec2login}, $form_login_response, );

is( $client->_is_session_expired, 1, 'sessionid not exists');
is( $client->_form_login, 0, 'login with user/pass' );
is_deeply(
    $client->_set_auto_login,
    [ 0, 'justafakesessionid', undef, undef, undef, time() + 604800 ],
    'set auto login'
);
ok( $client->_is_logged_in, 'confirm form login status' );
$client->{'ua'}->{'cookie_jar'}->{'file'} = undef;
is ( $client->_save_cookie , undef,  'save cookie without file' );
$client->{'ua'}->{'cookie_jar'}->{'file'} = $cookie_file;
ok ( $client->_save_cookie, 'save cookie with file');
is ( $client->_get_cookie('blogresult'), undef, 'delete blogresult');


# Reinitilize the mocked useragent for reading a existed cookie file.
$client->{'ua'} = Test::LWP::UserAgent->new();
$client->{'ua'}->cookie_jar( { file => $cookie_file } );
$client->{'ua'}->agent($WWW::Xunlei::DEFAULT_USER_AGENT);

$client->{'ua'}
    ->map_response( qr{login.xunlei.com/sessionid/}, $form_login_response );


$client->_set_cookie('_x_a_', 'justafakesessionid', -604800*2);
is($client->_is_session_expired, 1);
$client->_set_cookie('_x_a_', 'justafakesessionid', 604800*2);
isnt($client->_is_session_expired, 1);
is($client->_session_login, 0);
is_deeply(
    $client->_set_auto_login,
    [ 0, 'justafakesessionid', undef, undef, undef, time() + 604800 ],
    'set auto login'
);
ok( $client->_is_logged_in, 'confirm session login status' );
$client->{'ua'}->{'cookie_jar'}->{'file'} = undef;
is ( $client->_save_cookie , undef,  'save cookie without file' );
$client->{'ua'}->{'cookie_jar'}->{'file'} = $cookie_file;
ok ( $client->_save_cookie, 'save cookie with file');
is ( $client->_get_cookie('blogresult'), undef, 'delete blogresult');


my $list_peer_response = HTTP::Response->new(
    '200', 'OK', undef,
    '{"rtn": 0, "peerList": [{"category": "", "status": 0, "name": "kusobako", '
    . '"vodPort": 8002, "company": "XUNLEI_ARM_LE_ARMV5TE", '
    . '"pid": "F9367B658ED6217X0007", "lastLoginTime": 1446409025, '
    . '"accesscode": "", "localIP": "10.1.1.13", '
    . '"location": "\u5317\u4eac\u5e02 \u7535\u4fe1", "online": 1, '
    . '"path_list": "C:/", "type": 30, "deviceVersion": 22153310}]}',
);

note explain $list_peer_response;
$client->{'ua'}
    ->map_response( qr{homecloud.yuancheng.xunlei.com/listPeer}, $list_peer_response );


ok($client->list_downloaders);
my $d = $client->list_downloaders->[0];
isa_ok($d, 'WWW::Xunlei::Downloader');

done_testing();