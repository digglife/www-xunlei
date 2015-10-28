use Test::More;

use WWW::Xunlei;

my $client = WWW::Xunlei->new('whatever@cpan.org', 'whatever');
ok( defined $client && ref $client eq 'WWW::Xunlei' );
done_testing();

