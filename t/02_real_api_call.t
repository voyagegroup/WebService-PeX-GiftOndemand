use strict;
use warnings;

use Test::More;
use Test::Exception;
use WebService::PeX::GiftOndemand;
use t::lib::Utils qw/config/;

SKIP: {
    skip "When LIVE_TEST=1, test access real API", 2, unless $ENV{LIVE_TEST};


    #
    # This subtest needs to real API access
    #

    subtest 'Use invalid client' => sub {
        subtest 'Invalid password cause Unauthorized error' => sub {
            my $pex = WebService::PeX::GiftOndemand->new(
                    partner_code => 'genesix',
                    api          => 'https://api.pex.jp.dev.pex.jp/gift/1.0',
                    password     => 'invalid pass',
                    salt         => 'salt'
                );
            throws_ok {
                $pex->withdraw(
                        gift_type => 'itunes500',
                        user_id   => 'test' . time,
                        trade_id  => 'test' . time
                    );
            } qr/401 Unauthorized/, "Die when invalid password used";
        };

        subtest 'Invalid partner code cause Not Found error' => sub {
            my $pex = WebService::PeX::GiftOndemand->new(
                    partner_code => 'genesixx',
                    api          => 'https://api.pex.jp.dev.pex.jp/gift/1.0',
                    password     => 'invalid pass',
                    salt         => 'salt'
                );
            throws_ok {
                $pex->withdraw(
                        gift_type => 'itunes500',
                        user_id   => 'test' . time,
                        trade_id  => 'test' . time
                    );
            } qr/404 Not Found/, "Die when invalid partner code used";
        };
    };

    subtest 'Withdraw giftcode' => sub {
        my $cli = WebService::PeX::GiftOndemand->new(
                partner_code => config->{partner_code},
                api          => config->{api},
                password     => config->{password},
                salt         => config->{salt}
            );

        subtest 'Success withdraw code' => sub {
            my $ret = $cli->withdraw(
                gift_type => 'pex1000',
                user_id   => 'g6test' . time,
                trade_id => 'g6test' . time
            );

            is($ret->{response_code}, "OK", "Resposne code is OK");
            ok($ret->{gift_data}{code});
            ok($ret->{gift_data}{manage_code});
            is($ret->{gift_data}{gift_identify_code}, "pex1000");
        };

        subtest 'API returns NOW MAINTENANCE' => sub {
            my $ret = $cli->withdraw(
                gift_type => 'testgift500',
                user_id   => 'g6test',
                trade_id => 'testtradeid01'
            );

            is($ret->{gift_data}, undef, "No gift code");
            is($ret->{response_code}, "NG", "Resposne code is NG");
            is($ret->{detail_code}, "01", "Detail code is 01");
            is($ret->{message}, "NOW_MAINTENANCE", "message is now maintenance");
        };

        subtest 'API returns DUPLICATE TRAN' => sub {
            my $ret = $cli->withdraw(
                gift_type => 'testgift500',
                user_id   => 'g6test',
                trade_id => 'testtradeid03'
            );

            is($ret->{gift_data}, undef, "No gift code");
            is($ret->{message}, "DUPLICATE_TRAN");
        };

        subtest 'API returns DETECT FRAUD USER' => sub {
            my $ret = $cli->withdraw(
                gift_type => 'testgift500',
                user_id   => 'g6test',
                trade_id => 'testtradeid07'
            );

            is($ret->{response_code}, "NG");
            is($ret->{gift_data}, undef, "No result");
            is($ret->{detail_code}, "07");
            is($ret->{message}, "DETECT_FRAUD_USER");
        };

        subtest 'API returns EMPTY GIFT STOCK' => sub {
            my $ret = $cli->withdraw(
                gift_type => 'testgift500',
                user_id   => 'g6test',
                trade_id => 'testtradeid04'
            );

            is($ret->{gift_data}, undef, "No gift code");
            is($ret->{response_code}, "NG");
            is($ret->{detail_code}, "04");
            is($ret->{message}, "EMPTY_GIFT_STOCK");
        };

        subtest 'API returns INVALID FORMAT' => sub {
            throws_ok {
                $cli->withdraw(
                    gift_type => 'testgift500',
                    user_id   => 'g6test',
                    trade_id => 'testtradeid21'
                );
            } qr/INVALID_FORMAT/, "Die when invalid format";
        };

        subtest 'API returns INVALID GIFT_IDENTIFY_CODE' => sub {
            throws_ok {
                $cli->withdraw(
                    gift_type => 'testgift999',
                    user_id   => 'g6test' . time,
                    trade_id => 'g6test'. time
                );
            } qr/INVALID_GIFT_IDENTIFY_CODE/, "Die when invalid gift id";
        };

        subtest 'API returns INTERNAL SERVER ERROR' => sub {
            my $ret = $cli->withdraw(
                gift_type => 'testgift500',
                user_id   => 'g6test',
                trade_id => 'testtradeid99'
            );

            is($ret->{gift_data}, undef, "No gift code");
            is($ret->{response_code}, "NG");
            is($ret->{detail_code}, "99");
            is($ret->{message}, "INTERNAL_ERROR");
        };

    };

    subtest 'Inquiry giftcode' => sub {
        my $cli = WebService::PeX::GiftOndemand->new(
                partner_code => config->{partner_code},
                api          => config->{api},
                password     => config->{password},
                salt         => config->{salt}
            );

        subtest 'Inquiry previous trade' => sub {
            my $trade_id = 'g6test' . time;

            my $gift = $cli->withdraw(
                gift_type => 'pex1000',
                user_id   => $trade_id,
                trade_id => $trade_id
            );

            ok($gift->{gift_data});

            my $ret = $cli->inquiry(
                trade_id => $trade_id
            );
            ok($ret);
            is($ret->{response_code}, "OK", "Resposne code is OK");
            is($ret->{trade_id}, $trade_id);
            ok($ret->{gift_data});
            ok($ret->{gift_data}{code});
            ok($ret->{gift_data}{manage_code});
            ok($ret->{gift_data}{send_time});
        };

        subtest 'Invalid trade id' => sub {
            my $ret = $cli->inquiry(
                trade_id => 999
            );
            ok($ret);
            is($ret->{response_code}, "NG", "Resposne code is NG");
            is($ret->{detail_code}, "08");
            is($ret->{message}, "NONE");
        };
    };
}

done_testing();

