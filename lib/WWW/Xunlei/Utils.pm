package WWW::Xunlei::Utils;
use Exporter 'import';
@EXPORT = qw(urlencode md5pass);

use File::Spec;
use URI::Escape;
use Digest::MD5 qw(md5_hex);

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

sub md5pass {
    my $pass = shift;
    if ( $pass !~ /^[0-9a-f]{32}$/i ) {
        $pass = md5_hex( md5_hex($pass) );
    }
    return $pass;
}

1;