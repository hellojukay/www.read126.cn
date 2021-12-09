#!/usr/bin/env perl
use strict;
use warnings;
use HTTP::Tiny;
use Encode;
use HTML::Element;
use HTML::Query 'Query';

binmode( STDOUT, "encoding(UTF-8)" );

sub get ($) {
    my $response = HTTP::Tiny->new->get(shift);
    die "Failed!\n" unless $response->{success};
    return decode( "gb2312", $response->{content} );
}

# 获取章节列表
sub get_novels ($) {
    my $q     = Query( text => shift );
    my @links = $q->query('td>a[title]')->get_elements();
    return map {
        sprintf "%s http://www.read126.cn/%s", $_->as_trimmed_text,
          $_->attr('href')
    } @links;
}

my $url = $ARGV[0];
unless ($url) {
    printf "please enter url link\n";
    exit(1);
}
my $text   = get($url);
my @novels = get_novels($text);
foreach my $novel (@novels) {
    print "$novel\n";
}

