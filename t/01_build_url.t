use strict;
use warnings;

use Test::More;
use Test::Exception;
use WebService::PeX::GiftOndemand;

subtest 'get_instance' => sub {
    my $instance = WebService::PeX::GiftOndemand->new({
            partner_code => 'voyagegroup',
            api          => 'http://api.pex.jp',
            password     => 'password',
            salt         => 'salt'
        });
    ok($instance);
};

subtest 'signature()' => sub {
    my $instance = WebService::PeX::GiftOndemand->new(
            partner_code => 'genesix',
            api          => 'http://pex.jp',
            password     => 'password',
            salt         => 'salt'
        );
    my $ret = $instance->signature("abcdefg");
    is($ret, "cafa570e0553c31421ce7037a5d1b6463a192802");
};

subtest 'build_withdraw_url()' => sub {
    my $instance = WebService::PeX::GiftOndemand->new(
            partner_code => 'genesix',
            api          => 'http://pex.jp',
            password     => 'password',
            salt         => 'salt'
        );

    my $user_id = $instance->user_identify_code('saruhei');
    my $time = time;

    my $ret = $instance->build_withdraw_url(
        gift_type => 'itunes500',
        user_id   => 'saruhei',
        trade_id  => 123
    );

    my $query_str = "gift_identify_code=itunes500". 
    "&partner_code=genesix".
    "&response_type=json".
    "&timestamp=${time}".
    "&trade_id=123".
    "&user_identify_code=$user_id";
    my $signature = $instance->signature($query_str);

    is($ret, "http://pex.jp/pull?${query_str}&signature=${signature}");
};

subtest 'build_inquiry_url()' => sub {
    my $instance = WebService::PeX::GiftOndemand->new(
            partner_code => 'genesix',
            api          => 'http://pex.jp',
            password     => 'password',
            salt         => 'salt'
        );

    my $time = time;
    my $query_str = "partner_code=genesix".
    "&response_type=json".
    "&timestamp=${time}".
    "&trade_id=123";
    my $signature = $instance->signature($query_str);

    my $ret = $instance->build_inquiry_url(
        trade_id  => 123
    );
    is($ret, "http://pex.jp/inquiry?${query_str}&signature=${signature}");
};

done_testing();

