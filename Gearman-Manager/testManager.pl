#!/usr/bin/perl
use lib qw( ./lib );
use Gearman::Manager;

Gearman::Manager->new( 
    { 
        global=>{servers=>['mabook.com:9998']},
        'TestWorker'=>{count=>5,max_jobs=>5},
    }
)->start();


