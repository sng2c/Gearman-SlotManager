package Gear;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);

use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(gstart gstop);
sub gstart{
    $pid = fork;
    if( $pid ){
        open(FILE,'>gear.pid');
        print FILE $pid;
        close(FILE);
        DEBUG "gearmand STARTED #$pid";
    }
    else{
        exec('gearmand -p 9998');
    }
}

sub gstop{
    open(FILE,'gear.pid');
    chomp($pid=<FILE>);
    close(FILE);

    kill 9, $pid;
    unlink 'gear.pid';
    DEBUG "gearmand STOPPED #$pid";
}
