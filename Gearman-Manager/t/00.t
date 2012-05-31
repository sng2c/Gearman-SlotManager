use Test::More;


use_ok('Gearman::Server');

$pid = fork;
if( $pid ){
    open(FILE,'>gearmand.pid');
    print FILE $pid;
    close(FILE);
}
else{
    exec('gearmand -p 9998');
}

done_testing();
