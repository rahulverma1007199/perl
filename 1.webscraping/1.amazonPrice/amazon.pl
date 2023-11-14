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

package AmazonProducts;
use Moo;
has 'name' => (is => 'ro');
has 'price' => (is => 'ro');

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

     my @amazon_products;

     foreach my $eachProduct (@html_products){
          my $name_c = $eachProduct->look_down('_tag','div',class => qr/s-title-instructions-style/);
          my $name = $name_c ? $name_c->as_text : "";
          my $price_c = $eachProduct->look_down('_tag','span',class => qr/a-price-whole/);
          my $price = $price_c ? $price_c->as_text : 0;
          $price =~ tr/,//d;
          if(is_positive($price) == 0){
               next;
          }

        my $amazon_product = AmazonProducts->new(price =>$price, name =>$name );

        push @amazon_products,$amazon_product;
     }

     my @csv_header = qw(price name);

     my $csv = Text::CSV->new({binary => 1,auto_diag => 1 ,eol => $/});
     open my $file, '>:encoding(utf8)','eachProduct.csv' or die "failed to create file : $!";

     $csv->print($file, \@csv_header);

     foreach my $product (@amazon_products){
          my @row = map {$product->$_} @csv_header;
          $csv->print($file, \@row);
     }

     close $file;
}

1;