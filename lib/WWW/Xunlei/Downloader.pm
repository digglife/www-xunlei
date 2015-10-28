package WWW::Xunlei::Downloader;

use strict;
use warnings;

sub new {
    my $class = shift;
    my ( $client, $downloader ) = @_;

    my $self = { 'client' => $client, };
    $self->{$_} = $downloader->{$_} for (%$downloader);

    bless $self, $class;
    return $self;
}

sub is_online {
    my $self = shift;

    return $self->{'online'};
}

sub login {
    my $self = shift;

    my $res = $self->_request('login');
}

sub get_config {
    my $self = shift;

    my $res = $self->_request('settings');
}

sub set_config {
    my $self   = shift;
    my $config = shift;

    my $parameters;

    # Todo: validate the keys of $config.
    for my $k ( keys %$config ) {
        $parameters->{$k} = $config->{$k};
    }

    my $res = $self->_request( 'settings', $parameters );
}

sub unbind {
    my $self = shift;

    my $res = $self->_request('unbind');
}

sub rename {
    my $self = shift;
    my ( $pid, $new_name ) = @_;
    my $parameters = { 'boxname' => $new_name, };

    my $res = $self->_request( 'rename', $parameters );
}

sub get_box_space {
    my $self = shift;

    my $res = $self->_request('boxSpace');
    return wantarray ? @{ $res->{'space'} } : $res->{'space'};
}

sub list_tasks {
    my $self = shift;

    my ( $type, $pos, $number ) = @_;

    my $parameters = {
        'type'   => $type,
        'pos'    => $pos,
        'number' => $number,
    };

    my $res = $self->_request( 'list', $parameters );
}

sub url_check {
    my $self = shift;
    my ( $url, $type ) = @_;

    my $parameters = {
        'url'  => $url,
        'type' => $type,
    };

    my $res = $self->_request( 'urlCheck', $parameters );

}

sub url_resolve {
    my $self = shift;
    my $url  = shift;

    my $data = { 'url' => $url };

    my $res = $self->_request( 'urlResolve', undef, $data );
    return $res->{'taskInfo'};
}

sub create_task_info {
    my $self = shift;

    my ( $url, $filename ) = @_;

    my $task = {
        'gcid'     => "",
        'cid'      => '',
        'filesize' => 0,
        'ext_json' => { 'autoname' => 1 },
    };

    if ( $url =~ /^(http|https|ftp|magnet|ed2k|thunder|mms|rtsp)\:.+/ ) {
        my $res = $self->url_resolve($url);
        $task = {
            'url'      => $res->{'url'},
            'name'     => $res->{'name'},
            'filesize' => $res->{'size'},
        };
    }
    else {
        die "Not a valid Network Protocol";

        #return;
    }

    $task->{'ext_json'}->{'autoname'}
        = ( !$filename || $task->{'name'} eq $filename ) ? 1 : 0;

    return $task;
}

sub create_task {
    my $self = shift;
    my ( $url, $filename, $path ) = @_;

    my $task = $self->create_task_info( $url, $filename );

    my $res = $self->create_tasks( [$task], $path );
    return wantarray ? @{ $res->{'tasks'} } : $res->{'tasks'};
}

sub create_tasks {
    my $self = shift;
    my ( $tasks, $path ) = @_;

    my $data;
    $data->{'tasks'} = $tasks;
    $data->{'path'} = $path || $self->get_config->{'defaultPath'};

    my $res = $self->_request( 'createTask', undef, $data );
}

sub _request {
    my $self = shift;
    my ( $action, $parameters, $data ) = @_;

    $parameters->{'pid'} = $self->{'pid'};

    unless ( $self->is_online ) {
        die "Downloader is not Online. Please check Xunlei Remote Service.";
    }

    my $res = $self->{'client'}->_yc_request( $action, $parameters, $data );
    if ( $res->{'rtn'} != 0 ) {

        # Todo: Handling not login failed here.
        die "Request Error: $res->{'rtn'}";
    }

    return $res;
}

1;
