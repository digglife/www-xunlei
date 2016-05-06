use Test::More;
use Test::LWP::UserAgent;
use File::Temp qw/tempfile tempdir/;
use File::Spec::Functions;
use WWW::Xunlei;

#$WWW::Xunlei::DEBUG=1;
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

is( $client->_is_session_expired, 1, 'sessionid not exists' );
is( $client->_form_login,         0, 'login with user/pass' );
is_deeply(
    $client->_set_auto_login,
    [ 0, 'justafakesessionid', undef, undef, undef, time() + 604800 ],
    'set auto login'
);
ok( $client->_is_logged_in, 'confirm form login status' );
$client->{'ua'}->{'cookie_jar'}->{'file'} = undef;
is( $client->_save_cookie, undef, 'save cookie without file' );
$client->{'ua'}->{'cookie_jar'}->{'file'} = $cookie_file;
ok( $client->_save_cookie, 'save cookie with file' );
is( $client->_get_cookie('blogresult'), undef, 'delete blogresult' );

# Reinitilize the mocked useragent for reading a existed cookie file.
$client->{'ua'} = Test::LWP::UserAgent->new();
$client->{'ua'}->cookie_jar( { file => $cookie_file } );
$client->{'ua'}->agent($WWW::Xunlei::DEFAULT_USER_AGENT);

$client->{'ua'}
    ->map_response( qr{login.xunlei.com/sessionid/}, $form_login_response );

$client->_set_cookie( '_x_a_', 'justafakesessionid', -604800 * 2 );
is( $client->_is_session_expired, 1 );
$client->_set_cookie( '_x_a_', 'justafakesessionid', 604800 * 2 );
isnt( $client->_is_session_expired, 1 );
is( $client->_session_login, 0 );
is_deeply(
    $client->_set_auto_login,
    [ 0, 'justafakesessionid', undef, undef, undef, time() + 604800 ],
    'set auto login'
);
ok( $client->_is_logged_in, 'confirm session login status' );
$client->{'ua'}->{'cookie_jar'}->{'file'} = undef;
is( $client->_save_cookie, undef, 'save cookie without file' );
$client->{'ua'}->{'cookie_jar'}->{'file'} = $cookie_file;
ok( $client->_save_cookie, 'save cookie with file' );
is( $client->_get_cookie('blogresult'), undef, 'delete blogresult' );

my $list_peer_response = HTTP::Response->new(
    '200',
    'OK',
    undef,
    '{"rtn": 0, "peerList": [{"category": "", "status": 0, "name": "kusobako", '
        . '"vodPort": 8002, "company": "XUNLEI_ARM_LE_ARMV5TE", '
        . '"pid": "F9367B658ED6217X0007", "lastLoginTime": 1446409025, '
        . '"accesscode": "", "localIP": "10.1.1.13", '
        . '"location": "\u5317\u4eac\u5e02 \u7535\u4fe1", "online": 1, '
        . '"path_list": "C:/", "type": 30, "deviceVersion": 22153310}]}',
);

#note explain $list_peer_response;
$client->{'ua'}->map_response( qr{homecloud.yuancheng.xunlei.com/listPeer},
    $list_peer_response );

ok( $client->get_downloaders, 'list downloaders' );
my $d = $client->get_downloaders->[0];
isa_ok( $d, 'WWW::Xunlei::Downloader' );

my $d = $client->get_downloader('kusobako');
isa_ok( $d, 'WWW::Xunlei::Downloader',
    'kusobako is a "WWW::Xunlei::Downloader" object' );
is( $d->{'pid'}, 'F9367B658ED6217X0007', 'kusobako\'s ID is right' );

#========================================
# Now start test WWW::Xunlei::Downloader
#========================================

is( $d->is_online, 1, "Online" );

my $json = {
    'autoDlSubtitle'     => 0,
    'autoOpenLixian'     => 1,
    'autoOpenVip'        => 1,
    'defaultPath'        => 'C=>/TDDOWNLOAD/',
    'downloadSpeedLimit' => -1,
    'maxRunTaskNumber'   => 1,
    'msg'                => '',
    'rtn'                => 0,
    'slEndTime'          => 1440,
    'slStartTime'        => 0,
    'syncRange'          => 0,
    'uploadSpeedLimit'   => -1
};

my $config_response
    = HTTP::Response->new( '200', 'OK', undef, JSON::encode_json($json), );

#note explain $config_response;

$client->{'ua'}->map_response( qr{homecloud.yuancheng.xunlei.com/settings},
    $config_response );
is_deeply( $d->get_config, $json );

$json->{'autoDlSubtitle'}      = 1;
$config_response->{'_content'} = JSON::encode_json($json);
$client->{'ua'}->map_response( qr{homecloud.yuancheng.xunlei.com/settings},
    $config_response );
is_deeply( $d->set_config(%$json), $json );

$config_response->{'_content'} = '{"rtn":0}';
$client->{'ua'}->map_response( qr{homecloud.yuancheng.xunlei.com/rename},
    $config_response );
is_deeply( $d->rename('hezi'), { 'rtn', 0 } );

my $space = {
    "msg"   => "",
    "rtn"   => 0,
    "space" => [ { "path" => "C", "remain" => "640222560256" } ]
};
$config_response->{'_content'} = JSON::encode_json($space);
$client->{'ua'}->map_response( qr{homecloud.yuancheng.xunlei.com/boxSpace},
    $config_response );
is_deeply( @{ $d->get_box_space }, @{ $space->{'space'} } );

my $tasks = {
    'recycleNum'    => 0,
    'serverFailNum' => 0,
    'rtn'           => 0,
    'completeNum'   => 969,
    'sync'          => 0,
    'dlNum'         => 1,
    'tasks'         => [
        {   'failCode'   => 0,
            'vipChannel' => {
                'available' => 0,
                'failCode'  => 0,
                'opened'    => 0,
                'type'      => 0,
                'dlBytes'   => 0,
                'speed'     => 0
            },
            'name'          => 'file1.tar.gz',
            'url'           => 'http=>//www.digglife.net/files/file1.tar.gz',
            'type'          => 1,
            'lixianChannel' => {
                'failCode'       => 0,
                'state'          => 2,
                'dlBytes'        => 0,
                'serverProgress' => 0,
                'serverSpeed'    => 0,
                'speed'          => 0
            },
            'subList'      => [],
            'id'           => '980',
            'state'        => 0,
            'remainTime'   => 0,
            'downTime'     => 9,
            'progress'     => 0,
            'path'         => '/tmp/thunder/volumes/C=>/TDDOWNLOAD/',
            'speed'        => 0,
            'createTime'   => 1458534004,
            'completeTime' => 1458534013,
            'size'         => 0
        }
    ]
};

$config_response->{'_content'} = JSON::encode_json($tasks);
$client->{'ua'}->map_response( qr{homecloud.yuancheng.xunlei.com/list},
    $config_response );
is_deeply( @{ $d->list_running_tasks() }, @{ $tasks->{'tasks'} } );

done_testing();
