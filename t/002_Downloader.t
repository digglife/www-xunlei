use Test::More;
use Test::MockObject;
use Test::LWP::UserAgent;
use File::Temp qw/tempfile tempdir/;
use File::Spec::Functions;
use WWW::Xunlei;

my $client = WWW::Xunlei->new( 'zshengli@cpan.org', 'matrix');


$client->{'ua'} = Test::LWP::UserAgent->new();
$client->{'ua'}->cookie_jar( { file => $cookie_file } );
$client->{'ua'}->agent($WWW::Xunlei::DEFAULT_USER_AGENT);

my $list_peer_response = HTTP::Response->new(
    '200', 'OK', undef,
    '{"rtn": 0, "peerList": [{"category": "", "status": 0, "name": "kusobako", '
    . '"vodPort": 8002, "company": "XUNLEI_ARM_LE_ARMV5TE", '
    . '"pid": "F9367B658ED6217X0007", "lastLoginTime": 1446409025, '
    . '"accesscode": "", "localIP": "10.1.1.13", '
    . '"location": "\u5317\u4eac\u5e02 \u7535\u4fe1", "online": 1, '
    . '"path_list": "C:/", "type": 30, "deviceVersion": 22153310}]}',
);

$client->{'ua'}
    ->map_response( qr{homecloud.yuancheng.xunlei.com/listPeer}, $list_peer_response );

my $d = $client->get_downloader('kusobako');
my $pid = $d->{'pid'};
isa_ok($d, 'WWW::Xunlei::Downloader');

ok($d->is_online, 1, "Online")

my $json = {
    'autoDlSubtitle'=> 0,
    'autoOpenLixian'=> 1,
    'autoOpenVip'=> 1,
    'defaultPath'=> 'C=>/TDDOWNLOAD/',
    'downloadSpeedLimit'=> -1,
    'maxRunTaskNumber'=> 1,
    'msg'=> '',
    'rtn'=> 0,
    'slEndTime'=> 1440,
    'slStartTime'=> 0,
    'syncRange'=> 0,
    'uploadSpeedLimit'=> -1
};


my $config_response = HTTP::Response->new(
    '200', 'OK', undef, JSON::encode_json($json),
);

$client->{'ua'}->map_response( qr{homecloud.yuancheng.xunlei.com/settings}, $config_response );
is_deeply($d->get_config, $json);

$json->{'autoDlSubtitle'} = 1;
$config_response->{'_content'} = JSON::encode_json($json);
$client->{'ua'}->map_response( qr{homecloud.yuancheng.xunlei.com/settings}, $config_response );
is_deeply($d->set_config($json), $json);

$config_repsonse->{'_content'} = JSON::encode_json('{"rtn":0}');
$client->{'ua'}->map_response( qr{homecloud.yuancheng.xunlei.com/rename}, $config_respose );
is_deeply($d->rename("hezi"), {"rtn", 0});



