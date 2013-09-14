requires 'perl', '5.008001';

requires 'JSON';
requires 'Furl::HTTP';
requires 'Moo';
requires 'URI';
requires 'Digest::SHA1';
requires 'Digest::HMAC_SHA1';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Exception';
};

