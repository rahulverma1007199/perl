use strict;
use warnings;
use Selenium::Chrome;
use Text::CSV;
    
# Define a data structure where
# to store the scraped data
package PokemonProduct;
use Moo;
has 'url' => (is => 'ro');
has 'image' => (is => 'ro');
has 'name' => (is => 'ro');
has 'price' => (is => 'ro');
    
# initialize the Selenium driver
my $driver = Selenium::Chrome->new('bynary' => './chromedriver'); #'./chromedriver.exe' on Windows
# Visit the HTML page of the page to scrape
$driver->get('https://scrapeme.live/shop/');
    
# Select all HTML product elements
my @html_products =  $driver->find_elements('li.product', 'css');
    
# Initialize the list of objects that will contain the scraped data
my @pokemon_products;
    
# Iterate over the list of HTML products to
# extract data from them
foreach my $html_product (@html_products) {
   # Extract the data of interest from the current product HTML element
    my $url   = $driver->find_child_element($html_product, 'a', 'tag_name')->get_attribute('href');
        my $image = $driver->find_child_element($html_product, 'img', 'tag_name')->get_attribute('src');
    my $name  = $driver->find_child_element($html_product, 'h2', 'tag_name')->get_text();
    my $price = $driver->find_child_element($html_product, 'span', 'tag_name')->get_text();
    
    # Store the scraped data in a PokemonProduct object
    my $pokemon_product = PokemonProduct->new(url => $url, image => $image, name => $name, price => $price);
    
   # Add the PokemonProduct to the list of scraped objects
    push @pokemon_products, $pokemon_product;
}
    
# Close the browser instance
$driver->quit();
$driver->shutdown_binary;
    
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


# to capture screenshot
# $driver->capture_screenshot('screenshot.png');