[![Build Status](https://travis-ci.org/voyagegroup/WebService-PeX-GiftOndemand.png?branch=master)](https://travis-ci.org/voyagegroup/WebService-PeX-GiftOndemand)

# NAME

WebService::PeX::GiftOndemand - PeX ondemand gift exchange API wrapper

# SYNOPSIS

    use WebService::PeX::GiftOndemand;

    my $gift = WebService::PeX::GiftOndemand->new(
       partner_code => 'voyagegroup',
       api          => 'https://api.pex.jp.dev.pex.jp/foo',
       password     => 'password4signature',
       salt         => 'nz93;r3klalk[-9'
    );

    my $ret = $gift->withdraw(
       gift_type => 'itunes500',
       user_id   => '1',
       trade_id  => '100'
    );

    # withdraw method returns /pull API response
    my $code = $ret->{gift_data}{code};

    # inquiry method returns /inquiry API response
    my $check = $gift->inquiry(
       trade_id  => '100'
    );

# DESCRIPTION

This module provides PeX ondemando gift exchange API caller

withdraw and inquiry method die when..

    - 401 Unauthorized
    - 404 Not Found
    - 500 Internal Server Error
    - API returns INVALID FORMAT error
    - API returns INVALID RESPONSE_TYPE error
    - API returns INVALID TRADE_ID error
    - API returns INVALID TIMESTAMP error
    - API returns INVALID SIGNATURE error

# SEE ALSO

[http://pex.jp/alliance/ondemand](http://pex.jp/alliance/ondemand)

# LICENSE

Copyright (C) VOYAGE GROUP, inc.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Takashi Nishibayashi <takashi\_nishibayashi@voyagegroup.com>
