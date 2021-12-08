#!/usr/bin/env perl
use strict;
use warnings;
use HTTP::Tiny;
use Encode;
use HTML::Element;
use HTML::Query 'Query';
use Term::ANSIColor;
use IO::Handle;
STDOUT->autoflush(1);

binmode( STDOUT, "encoding(UTF-8)" );

sub get ($) {
        my $response = HTTP::Tiny->new->get(shift);
        die "Failed!\n" unless $response->{success};
        return decode( "gb2312", $response->{content} );
}

# 获取文章内容
sub get_content ($) {
        my $html = shift;
        my $q    = Query( text => $html );
        return $q->query('[id] .Content')->first()->as_trimmed_text;
}

# 获取小说名字
sub get_novel ($) {
        my $q = Query( text => shift );
        return $q->query('#H2Title')->first()->as_trimmed_text;
}

# 获取章节列表
sub get_chapter ($) {
        my $q     = Query( text => shift );
        my @links = $q->query('.ListItem a')->get_elements();
        return map {
                sprintf "%s http://www.read126.cn/%s\n", $_->as_trimmed_text,
                $_->attr('href')
        } @links;
}

my $url = $ARGV[0];
unless ($url) {
        printf "please enter url link\n";
        exit(1);
}
my $text     = get($url);
my $novel    = get_novel($text);
my @chapters = get_chapter($text);


$novel = $novel =~ s/[\u0020]|\s//gr;
chomp $novel;
open( my $fh, ">", $novel . ".txt" )
        or die "can not create file $novel.txt $!\n";
binmode( $fh, "encoding(UTF-8)" );
printf "%s\n", $novel;
foreach my $chapter (@chapters) {
        my ( $title, $url ) = split /\s+/, $chapter;
        chomp $title;
        chomp $url;
        my $content;
        DOWNLOAD:
        eval {
                $content = get_content( get($url) );
                $content = $content =~ s/[\u0020]|\s//gr;
                unless ( length($content) ) {
                        print colored(['bright_red on_black'], "try $url", "\n");
                        sleep(3);
                        goto DOWNLOAD ;
                }
        } ;
        goto DOWNLOAD unless($content);
        printf "%s\t%d\t%s\n",$title,length($content), $url;
        printf $fh "%s\n\n%s", $title, $content;
}

close($fh);

