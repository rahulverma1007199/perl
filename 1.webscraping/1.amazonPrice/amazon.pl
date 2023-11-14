use strict;
use warnings;
use Data::Dumper;

use Path::Tiny;
use HTTP::Tiny;
use HTML::TreeBuilder;
use Text::CSV;

my $Path = path("./tmp.txt");

my @content = $Path->lines;
my $size = @content;

package PokenmonProducts;
use Moo;
has 'price' => (is => 'ro');
has 'image' => (is => 'ro');
has 'name' => (is => 'ro');
has 'url' => (is => 'ro');

sub is_positive {
     my ($num) = @_;
     return $num > 0;
}


if($size == 0){
     my $http = HTTP::Tiny->new();
     my $response = $http->get('https://www.amazon.in/s?k=iphone+11');
     my $data = $response->{content};
     $Path->spew($data);
}else{

     my $data = $Path->slurp;

     my $tree = HTML::TreeBuilder->new();
     $tree->parse($data);

     my @html_products = $tree->look_down('_tag','div', class => qr/s-result-item/);

     my @pokenmon_products;

     foreach my $pokemon (@html_products){
          my $name_c = $pokemon->look_down('_tag','div',class => qr/s-title-instructions-style/);
        #   my $price = $pokemon->look_down('_tag','span')->as_text;
        #   my $url = $pokemon->look_down('_tag','a')->attr('href');
        #   my $image = $pokemon->look_down('_tag','img')->attr('src');
        my $name = $name_c ? $name_c->as_text : "";
        my $price_c = $pokemon->look_down('_tag','span',class => qr/a-price-whole/);
        my $price = $price_c ? $price_c->as_text : 0;
        $price =~ tr/,//d;
        if(is_positive($price) == 0){
          next;
        }
        my $url ="test";
        my $image = "test";

        my $pokenmon_product = PokenmonProducts->new(price =>$price , url => $url, image =>$image , name =>$name );

        push @pokenmon_products,$pokenmon_product;
     }

     my @csv_header = qw(url price name image);

     my $csv = Text::CSV->new({binary => 1,auto_diag => 1 ,eol => $/});
     open my $file, '>:encoding(utf8)','pokemon.csv' or die "failed to create file : $!";

     $csv->print($file, \@csv_header);

     foreach my $pokenmon (@pokenmon_products){
          my @row = map {$pokenmon->$_} @csv_header;
          $csv->print($file, \@row);
     }

     close $file;
}

1;