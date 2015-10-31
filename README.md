# NAME

WWW::Xunlei - Perl API For Official Xunlei Remote API.

# VERSION

version 0.04

# SYNOPSIS

    use WWW::Xunlei;
    my $client = WWW::Xunlei->new("username", "password");
    $client->login;
    # use the first downloader;
    my $downloader = $client->list_downloaders()->[0];
    # create a remote task;
    $downloader->create_task("http://www.cpan.org/src/5.0/perl-5.22.0.tar.gz");

# DESCRIPTION

`WWW::Xunlei` is a Perl Wrapper of Xunlei Remote Downloader API.
[Official Site of Xunlei Remote](http://yuancheng.xunlei.com)

**This module is now under deveopment. It's not stable.**

# METHODS

## new( "username", "password")

## login()

## list\_downloaders()

# AUTHOR

Zhu Sheng Li &lt;zshengli@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Zhu Sheng Li.

This is free software, licensed under:

    The MIT (X11) License
