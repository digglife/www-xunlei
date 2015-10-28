package WWW::Xunlei;
# ABSTRACT: Perl API For Official Xunlei Remote API.

use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Request::Common;
use JSON;
use URI::Escape;
use Digest::MD5 qw(md5 md5_hex md5_base64);

use File::Basename;
use Time::HiRes qw/time/;
use File::Spec;
use POSIX;

use Term::ANSIColor qw/:constants/;

use Data::Dumper;

use WWW::Xunlei::Downloader;

our $DEBUG;

use constant URL_LOGIN  => 'http://login.xunlei.com/';
use constant URL_REMOTE => 'http://homecloud.yuancheng.xunlei.com/';
use constant DEFAULT_USER_AGENT =>
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.11; rv:41.0) "
    . "Gecko/20100101 Firefox/41.0";
use constant URL_LOGIN_REFER => 'http://i.xunlei.com/login/2.5/?r_d=1';
use constant BUSINESS_TYPE   => '113';
use constant V               => '2';
use constant CT              => '0';

sub new {
    my $class = shift;
    my ( $user, $pass, %options ) = @_;
    my $self = {
        'ua'   => undef,
        'json' => undef,
        'user' => $user,
        'pass' => md5_hex( md5_hex($pass) ),
    };

    $self->{'ua'} = LWP::UserAgent->new;
    $self->{'ua'}->cookie_jar( { ignore_discard => 0 } );
    #$self->{'ua'}->cookie_jar();
    $self->{'ua'}->agent(DEFAULT_USER_AGENT);

    $self->{'json'} = JSON->new->allow_nonref;

    bless $self, $class;
    return $self;
}

sub list_downloaders {
    my $self = shift;

    my $parameters = {
        'type' => 0,
    };

    my $res = $self->_yc_request( 'listPeer', $parameters );

    if ( $res->{'rtn'} != 0 ) {
        die "Unable to get the Downloader List: $@";
    }

    my @downloaders;
    for my $p ( @{$res->{'peerList'}} ) {
        push @downloaders, WWW::Xunlei::Downloader->new($self, $p);
    }

    #return wantarray ? @{$res->{'peerList'}} : $res->{'peerList'};
    return wantarray ? @downloaders : \@downloaders;
}

sub bind {
    my $self = shift;

    my ( $key, $name ) = @_;

    my $parameters = {
        'boxname' => $name,
        'key'     => $key,
    };

    my $res = $self->_yc_request( 'bind', $parameters );
}

sub unbind {
    my $self = shift;
    my $pid  = shift;

    my $res = $self->_yc_request( 'unbind', { 'pid' => $pid } );
}

sub login {
    my $self        = shift;
    my $verify_code = uc $self->get_verify_code();
    die "$@" unless $verify_code;
    $self->_debug( "Verify Code: " . $verify_code );
    my $password   = md5_hex( $self->{'pass'} . $verify_code );
    my $parameters = {
        'u'          => $self->{'user'},
        'p'          => $password,
        'verifycode' => $verify_code,
    };

    # $self->{'ua'}->post(join( '/', URL_LOGIN, 'sec2login/'), $parameters);
    # $self->_debug($self->{'ua'});
    $self->_request( 'POST', URL_LOGIN . 'sec2login/', $parameters );
}

sub _is_login {
    my $self = shift;
    return $self->get_cookie('sessionid') ? 1 : 0;
}

sub get_verify_code {
    my $self       = shift;
    my $parameters = {
        'u'             => $self->{'user'},
        'business_type' => BUSINESS_TYPE,
        'cachetime'     => current_timestamp(),
    };
    $self->_request( 'GET', URL_LOGIN . 'check/', $parameters );
    my $check_result = $self->get_cookie('check_result');
    my $verify_code = ( split( ':', $check_result ) )[1];
    return $verify_code;
}

sub get_cookie {
    my $self = shift;
    my ( $key, $domain ) = @_;
    $domain ||= ".xunlei.com";
    my $cookie_jar = $self->{'ua'}->{'cookie_jar'};
    return $cookie_jar->{'COOKIES'}->{$domain}->{'/'}->{$key}->[1];
}

sub _yc_request {
    my $self = shift;
    my ( $action, $parameters, $data ) = @_;

    my $method = $data ? 'POST' : 'GET';
    my $uri = URL_REMOTE . $action;
    $parameters->{'v'} = V;
    $parameters->{'ct'} = CT;

    return $self->_request($method, $uri, $parameters, $data);
}

sub _request {
    my $self = shift;
    my ( $method, $uri, $parameters, $postdata ) = @_;
    my ( $form_string, $payload );
    if ($parameters) {
        $form_string = urlencode($parameters);
    }

    if ( $method ne 'GET' && !$postdata ) {

        # use urlencode parameters as post data when posting login form.
        $payload = $form_string;
    }
    else {
        $uri .= '?' . $form_string;
        if ( ref $postdata ) {
            $payload = $self->{'json'}->encode($postdata);
            $payload = urlencode({ 'json' => $payload });
        }
    }

    my $request = HTTP::Request->new( $method => $uri, undef, $payload );
    #$request->header( 'User-Agent' => DEFAULT_USER_AGENT );
    $request->header('Content-Type' => 'application/x-www-form-urlencoded');
    $self->_debug($request);
    my $response = $self->{'ua'}->request($request);
    die "$@" unless $response->is_success;
    my $content = $response->content;

    $self->_debug($content);

    #$self->_debug( $self->{'ua'} );

    $content =~ s/\s$//g;
    return "" unless ( length($content) );

    return $self->{'json'}->decode($content) if ( $content =~ /\s*[\[\{\"]/ );
}

sub current_timestamp {
    return int( time() * 1000 );
}

sub urlencode {
    my $data = shift;

    my @parameters;
    for my $key ( keys %$data ) {
        push @parameters,
            join( '=', map { uri_escape_utf8($_) } $key, $data->{$key} );
    }
    my $encoded_data = join( '&', @parameters );
    return $encoded_data;
}

sub _debug {
    my $self    = shift;
    my $message = shift;
    if ($DEBUG) {
        if ( ref $message ) { $message = Dumper($message); }
        my $date = strftime( "%Y-%m-%d %H:%M:%S", localtime );

        #$date .= sprintf(".%03f", current_timestamp());
        print BLUE "[ $date ] ", GREEN $message, RESET "\n";
    }
}

1;
