# NAME

WWW::Xunlei - Perl API For Official Xunlei Remote API.

# VERSION

version 0.06

# SYNOPSIS

    use WWW::Xunlei;
    my $client = WWW::Xunlei->new("username", "password");
    # use the first downloader;
    my $downloader = $client->list_downloaders()->[0];
    # create a remote task;
    $downloader->create_task("http://www.cpan.org/src/5.0/perl-5.22.0.tar.gz");

# DESCRIPTION

`WWW::Xunlei` is a Perl Wrapper of Xunlei Remote Downloader API.
[Official Site of Xunlei Remote](http://yuancheng.xunlei.com)

# METHODS

## new( $username, $password, \[cookie\_file=>'/path/to/cookie'\])

create a Xunlei client. Load or save Cookies to a plain text file with 
`cookie_file` option. The default session expire time is 7 days.

## bind($key, \[$name\])

Bind a new downloader with a activation code. The new downloader's name can
 be defined with the optional argument `$name`.

## list\_downloaders

List all the downloaders binding with your account. Return a list of
`WWW::Xunlei::Downloader` object.

## list\_downloader($name)

Get the downloader of which the name is $name. 
Return a `WWW::Xunlei::Downloader` object.

# AUTHOR

Zhu Sheng Li &lt;zshengli@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Zhu Sheng Li.

This is free software, licensed under:

    The MIT (X11) License
