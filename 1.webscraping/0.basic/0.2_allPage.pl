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
    
# initialize the HTML parser
my $tree = HTML::TreeBuilder->new();
  
# Initialize the list of objects that will contain the scraped data
my @pokemon_products;
    
# First page to scrape
my $first_page = "https://scrapeme.live/shop/page/1/";
    
# Initialize the list of pages to scrape
my @pages_to_scrape = ($first_page);
    
# Initializing the list of pages discovered
my @pages_discovered = ($first_page);
    
# Current iteration
my $i = 0;
    
# Max pages to scrape
my $limit = 5;
    
# Iterate until there is still a page to scrape or the limit is reached
while (@pages_to_scrape && $i < $limit) {
    # Get the current page to scrape by popping it from the list
    my $page_to_scrape = pop @pages_to_scrape;
    
    # Retrieve the HTML code of the page to scrape
    my $response = $http->get($page_to_scrape);
   
    # Parse the HTML document returned by the server
    $tree->parse($response->{content});
    
    # Select all HTML product elements
    my @html_products = $tree->look_down('_tag', 'li', class => qr/product/);
    
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
    
    # Retrieve the list of pagination URLs
    my @new_pagination_links = map { $_->attr('href') } $tree->look_down('_tag', 'a', class => 'page-numbers');
    
    # Iterate over the list of pagination links to find new URLs
    # to scrape
    foreach my $new_pagination_link (@new_pagination_links) {
        # If the page discovered is new
        unless (grep { $_ eq $new_pagination_link } @pages_discovered) {
            push @pages_discovered, $new_pagination_link;
    
            # If the page discovered needs to be scraped
            unless (grep { $_ eq $new_pagination_link } @pages_to_scrape) {
                push @pages_to_scrape, $new_pagination_link;
            }
        }
    }
    
    # Increment the iteration counter
    $i++;
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
