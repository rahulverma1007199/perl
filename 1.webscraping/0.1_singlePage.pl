use strict;
use warnings;
use HTTP::Tiny;
use HTML::TreeBuilder;
use Text::CSV;
    
# Define a data structure where
# to store the scraped data
package PokemonProduct;
use Moo;
has 'url' => (is => 'ro');
has 'image' => (is => 'ro');
has 'name' => (is => 'ro');
has 'price' => (is => 'ro');
    
# initialize the HTTP client
my $http = HTTP::Tiny->new();
# Retrieve the HTML code of the page to scrape
my $response = $http->get('https://scrapeme.live/shop/');
my $html_content = $response->{content};
print "$html_content\n";
    
# initialize the HTML parser
my $tree = HTML::TreeBuilder->new();
# Parse the HTML document returned by the server
$tree->parse($response->{content});
   
# Select all HTML product elements
my @html_products = $tree->look_down('_tag', 'li', class => qr/product/);
    
# Initialize the list of objects that will contain the scraped data
my @pokemon_products;
    
# Iterate over the list of HTML products to
# extract data from them
foreach my $html_product (@html_products) {
     # Extract the data of interest from the current product HTML element
     my $url = $html_product->look_down('_tag', 'a')->attr('href');
     my $image = $html_product->look_down('_tag', 'img')->attr('src');
     my $name = $html_product->look_down('_tag', 'h2')->as_text;
     my $price = $html_product->look_down('_tag', 'span')->as_text;
    
     # Store the scraped data in a PokemonProduct object
     my $pokemon_product = PokemonProduct->new(url => $url, image => $image, name => $name, price => $price);
    
     # Add the PokemonProduct to the list of scraped objects
     push @pokemon_products, $pokemon_product;
}
    
# Define the header row of the CSV file
my @csv_headers = qw(url image name price);
    
# Create a CSV file and write the header
my $csv = Text::CSV->new({ binary => 1, auto_diag => 1, eol => $/ });
open my $file, '>:encoding(utf8)', 'products.csv' or die "Failed to create products.csv: $!";
$csv->print($file, \@csv_headers);
    
# Populate the CSV file
foreach my $pokemon_product (@pokemon_products) {
    # PokemonProduct to CSV record
    my @row = map { $pokemon_product->$_ } @csv_headers;
     $csv->print($file, \@row);
}
    
# Release the file resources
close $file;
