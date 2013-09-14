package WebService::PeX::GiftOndemand;

use strict;
use warnings;

use JSON qw/decode_json/;
use Furl::HTTP;
use URI;
use URI::QueryParam;
use URI::Escape;
use Digest::SHA1 qw(sha1_hex);
use Digest::HMAC_SHA1 qw(hmac_sha1_hex);
use Moo;

our $VERSION = "0.01";

has api          => (is => 'ro', required => 1);
has password     => (is => 'ro', required => 1);
has partner_code => (is => 'ro', required => 1);
has salt         => (is => 'ro', required => 1);

has agent => (is => 'rw', lazy => 1, default => sub {
    Furl::HTTP->new(
        headers => [
            'Connection'      => 'close', # disable keep-alive
            'Accept-Encoding' => 'gzip',  # accepts gzip
        ],
        timeout => 10,
    );
});

sub post {
    my ($self, $url) = @_;
    my ($minor_version, $status, $message, $headers, $content) = $self->agent->post($url);

    return decode_json($content) if $status eq 200;
    die "${status} ${message}";
}

sub withdraw {
    my ($self, %params) = @_;
    my $url = $self->build_withdraw_url(%params);
    my $res = $self->post($url);

    if ($res->{response_code} eq "NG" && $res->{detail_code} =~ /^2/) {
        die $res->{message} . " with request ${url}"
    }
    $res;
}

sub build_withdraw_url {
    my ($self, %params) = @_;
    my $url = URI->new($self->withdraw_api);
    $url->query_param(gift_identify_code => $params{gift_type});
    $url->query_param(partner_code => $self->partner_code);
    $url->query_param(response_type => "json");
    $url->query_param(timestamp => time);
    $url->query_param(trade_id => $params{trade_id});
    $url->query_param(user_identify_code => $self->user_identify_code($params{user_id}));
    $url->query_param(signature => $self->signature($url->query));
    $url;
}

sub withdraw_api {
    my ($self) = @_;
    $self->api . "/pull";
}


sub inquiry {
    my ($self, %params) = @_;
    my $url = $self->build_inquiry_url(%params);
    my $res = $self->post($url);

    if ($res->{response_code} eq "NG" && $res->{detail_code} =~ /^2/) {
        die $res->{message} . " with request ${url}"
    }
    $res;
}

sub build_inquiry_url {
    my ($self, %params) = @_;
    my $url = URI->new($self->inquiry_api);
    $url->query_param(partner_code => $self->partner_code);
    $url->query_param(response_type => "json");
    $url->query_param(timestamp => time);
    $url->query_param(trade_id => $params{trade_id});
    $url->query_param(signature => $self->signature($url->query));
    $url;
}

sub inquiry_api {
    my ($self) = @_;
    $self->api . "/inquiry";
}


sub signature {
    my ($self, $query) = @_;
    my $encoded = uri_escape($query);
    hmac_sha1_hex($encoded, $self->password);
}

my $offset = 9 * 60 * 60; # +09:00
sub user_identify_code {
    my ($self, $user_id) = @_;
    my ($sec, $min, $hour, $mday, $mon, $year) = gmtime(time + $offset);
    sha1_hex($user_id . $self->salt . "$mday$mon$year");
}

1;

__END__

=encoding utf-8

=begin html

<img src="https://travis-ci.org/voyagegroup/WebService-PeX-GiftOndemand.png?branch=master">

=end html

=head1 NAME

WebService::PeX::GiftOndemand - PeX ondemand gift exchange API wrapper

=head1 SYNOPSIS

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

=head1 DESCRIPTION

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

=head1 SEE ALSO

L<http://pex.jp/alliance/ondemand>

=head1 LICENSE

Copyright (C) VOYAGE GROUP, inc.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Takashi Nishibayashi E<lt>takashi_nishibayashi@voyagegroup.comE<gt>

=cut

