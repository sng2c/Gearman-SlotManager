#!/usr/bin/perl
use lib qw( ./lib );
use Gearman::Manager;

Gearman::Manager->new( 
    { 
        global=>{servers=>['mabook.com:9998']},
        'TestWorker'=>{count=>2,max_jobs=>2},
        'TestWorkerAny'=>{count=>2,max_count=>5,max_jobs=>2,type=>'exec'},
    }
)->start();


