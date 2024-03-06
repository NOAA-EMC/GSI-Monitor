#! /usr/bin/perl

#------------------------------------------------------------------------
#  rgn_find_latest_cycle.pl
#
#    Return the latest cycle time or nothing if no data files are found.
#
#    Arguments:
#       --dir     : Required string value containing  $TANKdir/$SUFFIX.
#       --mon     : Optional monitor name, default is radmon.  
#
#------------------------------------------------------------------------

   use strict;
   use warnings;
   use Getopt::Long;
   use Scalar::Util qw(looks_like_number);
   use File::Find;

   my $latest_date;

   #---------------------------------------
   # Define the file processing subroutine
   #
   sub process_file {

      my $file = $_;

      # Define the regular expression to match 10-digit date strings
      my $date_regex = qr/\b(\d{10})\b/; 

      # Extract date string from the file name using the regex
      if ($file =~ $date_regex) {
         my $date_string = $1;

	 # Compare the current date string with the latest found
	 if (!$latest_date || $date_string > $latest_date) {
	    $latest_date = $date_string;
         }
      }
   }


   ##------------------------------------------------------------------
   ##------------------------------------------------------------------
   ##
   ##  begin main 
   ##
   ##------------------------------------------------------------------
   ##------------------------------------------------------------------

   my $dir  = '';
   my $mon  = 'radmon';

   GetOptions( 'dir=s' => \$dir,
               'mon:s' => \$mon );

   my $dirpath = $dir;
   my @mondirs;

   opendir(DIR, $dirpath) or die "Cannot open directory $!";
   while (my $entry = readdir(DIR)) {
      next if $entry =~ /^\./;  # Skip '.' and '..' entries

      # Check if the entry is a directory and contains the target string
      if (-d "$dirpath/$entry" && $entry =~ $mon) {
         push @mondirs, "$dirpath/$entry";
      }
   }

   closedir DIR;

   # Traverse @mondirs and process files
   foreach my $directory (@mondirs) {
      find(\&process_file, $directory);
   }

   # Print the latest date string
   if ($latest_date) {
      print "$latest_date";
   }

   exit;
