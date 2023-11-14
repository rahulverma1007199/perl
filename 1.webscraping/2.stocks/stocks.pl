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

package StocksList;
use Moo;
has 'Index' => (is => 'ro');
has 'Price' => (is => 'ro');
has 'Change' => (is => 'ro');
has 'Chg' => (is => 'ro');

sub is_positive {
     my ($num) = @_;
     return $num > 0;
}


if($size == 0){
     my $http = HTTP::Tiny->new();
     my $response = $http->get('https://www.moneycontrol.com/stocksmarketsindia/');
     my $data = $response->{content};
     $Path->spew($data);
}else{

     my $data = $Path->slurp;

     my $tree = HTML::TreeBuilder->new();
     $tree->parse($data);

     my @html_stocks = $tree->look_down('_tag','div', class => qr/tab-content/);

     my @stocks_list;

     foreach my $stock_table (@html_stocks){
     my $tBody = $stock_table->look_down('_tag','tbody');
     if(ref $tBody){
        for my $tr ($tBody->content_list) {
               my @values; 
               if(ref $tr){
               for my $td_val ($tr->content_list){
                    if(ref $td_val){
                         my $td = $td_val->as_text // "";
                         push @values, $td;
                    }
               }
               my ($index, $price, $change, $chg) = @values;
        my $each_stock = StocksList->new(Index =>$index , Price => $price, Change =>$change , Chg =>$chg );
        push @stocks_list,$each_stock;
               }
          }
     }
        


     }

     my @csv_header = qw(Index Price Change Chg);

     my $csv = Text::CSV->new({binary => 1,auto_diag => 1 ,eol => $/});
     open my $file, '>:encoding(utf8)','stock.csv' or die "failed to create file : $!";

     $csv->print($file, \@csv_header);

     foreach my $stock (@stocks_list){
          my @row = map {$stock->$_} @csv_header;
          $csv->print($file, \@row);
     }

     close $file;
}

1;