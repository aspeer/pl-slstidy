requires 'Capture::Tiny';
requires 'File::Temp';

on configure => sub {
    requires 'perl', '5.006';
};

on test => sub {
    requires 'Digest::MD5';
    requires 'File::Temp';
    requires 'File::Which';
    requires 'Test::More';
    suggests 'Test::Pod', '1.14';
};
