#!/usr/bin/perl


use v5.10;
use Data::Dumper;
use Data::Printer;

## http://habrahabr.ru/post/227493/
use Mojo::DOM;

use Encode;
use utf8;
use strict;
#my $output = `find ./Cache -type f -name file010.html | head -3`;
my $output = `find ./Cache -type f -name file\*.html | head -3000`;
#my $output = `find ./Cache -type f -name file300.html | head -3000`;

my @data = ();
foreach my $line (split /\n/, $output ) {
    #say $line;
    push @data, parse( $line );
#exit 0;
}


sub parse {
    my $file = shift;
    my $pre_data = shift;

    my $body;
    open FD, $file or die "Error: $!";
    $body .= $_ for <FD>;
    close FD;
    $body = decode('utf8',$body);

    #say $body;
    my $dom = Mojo::DOM->new( $body );

    my $div_col = $dom->find('div.borderwrapper');

    my $n =  scalar @$div_col;
    #say "Scalar: $n";

    for(my $i=0; $i<$n; $i++  ) {
        my $tmp = {};
        $tmp->{num} = $i;
        $tmp->{file} = $file;
        my $e = $div_col->[$i] . '';
        #my $e = $div_col->[$i]->join('ff'); # . '';
        #my $e = $div_col->[$i]->children->join();

        $dom = Mojo::DOM->new( $e );

        my $link = $dom->at('h3')->at('a');
        $tmp->{Institution} = $link->text;
        $tmp->{Link} = $link->attr('href');
        
        #->attr('href');
        #say 'Link: ', $link;

        my $names = $dom->at('h4');
        $tmp->{Names} =  ($names?$names->text:'');

        my $address = $dom->at('address')->find('span');
        my $an = scalar @$address;


        $tmp->{num_address} = $an;
        #say $address->join("\n");
        if( $an == 3 ) {
            # say "Here: ", $address;
            for(my $a  =0; $a <$an; $a++ ) {
                $tmp->{Street} = $address->[0]->text if $a == 0;
                $tmp->{Postcode} = $address->[1]->text if $a == 1;
                $tmp->{City} = $address->[2]->text if $a == 2;
            }
        } elsif( $an == 2 ) {
            #say $address->join();
            $tmp->{Postcode} = $address->[0]->text;
            $tmp->{City} = $address->[1]->text;
            #say '-'x40;
        } elsif( $an == 4 ) {
            #say $address->join("\n");
            $tmp->{AInfo} = $address->[0]->text;
            $tmp->{Street}   = $address->[1]->text;
            $tmp->{Postcode} = $address->[2]->text;
            $tmp->{City} = $address->[3]->text;
            #say '-'x40;

        }

        #say $address;#->text;
        #    my $t = $dom->at('table.eintraegemain');
        #    say $t;


        my $rows;
        my $nrows;
        my $tds;
        my $table1 = $dom->at('table.eintraegemain');
        #say "TABLE1: $table1"; 
        $rows = $table1->find('tr');
        $nrows = scalar @$rows;

        for( my $j=0; $j<$nrows; $j++ ) {
            $tds = $rows->[$j]->find('td');
            my $td0 = $tds->[0]->text;
            my $td1 = $tds->[1];
#say "TD0: $td0";
            if( $td0 eq 'Homepage:' ) {
                $tmp->{Homepage} = $td1->at('a')->at('span')->text;
                #say $i, ' ', $file, 'www:', $tmp->{Homepage};
            } elsif( $td0 eq 'E-Mail:' ) {
                my $e = $td1->at('a')->text;
                $e =~ s/\s/@/;
                #say $e;
                $tmp->{Email} = $e;
            } elsif( $td0 eq 'Telefon:' ) {
                my $ph= $td1->at('span')->text;
                $tmp->{Telefon} =  $ph;
            } elsif( uc $td0 eq 'FAX:' ) {
                #say "$td0 ", $td1->at('span')->text;
                $tmp->{Fax} = $td1->at('span')->text;
            } else {
                #say "$td0 abnormal contact";
            }
            #say "$td0"; # $td1";
        }

        my $table2 = $dom->at('table.eintragsub');
        if( $table2 ) {
            $rows = $table2->find('tr');
            $nrows = scalar @$rows;
            #say "NROWS2 ", scalar @$rows;
            for( my $j=0; $j<$nrows; $j++ ) {
                $tds = $rows->[$j]->find('td');
                my $ntds = scalar @$tds;
                if( $ntds == 2 ) {
                    my $td0 = $tds->[0]->text;
                    my $td1 = $tds->[1];
                    if( $td0 eq 'Sprachen:' ) {
                        #say $td1->text;
                        $tmp->{Language} = $td1->text;
                    }
                } else {
                    #say "TDSN: $ntds";
                    for( my $k=0; $k < $ntds; $k++ ) {
                        my $text = $tds->[$k]; 
                        if( $text =~ m/Spra/i ) {
                            die "$text Sprachen";
                        }
                    }
                }
            }
        } else {
            #say "table2  not defined";
        }
        say Dumper $tmp;
    }
} 
