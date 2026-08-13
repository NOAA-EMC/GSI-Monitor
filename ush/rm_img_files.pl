#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Scalar::Util qw(looks_like_number);
use File::Spec;

#---------------------------------------------------------------------
#  rm_img_files.pl
#
#  This script can be used to remove old image files from a specified
#  directory.  This script assumes a 10 digit cycle time is included
#  in the file name.  All other files will be ignored.
#
#  Arguments:
#    --dir    Directory from which files are to be removed.  
#               Note: if the --sdirs param is included then --dir 
#               should be the parent directory to the specified sdirs.
#    --ncyc   Number of cycles to retain.  All cycle times from 
#             filenames in each directory are sorted and all files
#             older than ncyc are removed.  If unspecified the default
#             is 20 cycles.
#    --sdirs  A list of subdirectories (--sdirs=dir1,dir2,dir3).  If
#             not included then sdirs is ignored and only $dir 
#             (above) is evaluated and cleaned.
#---------------------------------------------------------------------

#-------------------------------------------------------------------
#  Subroutine uniq
#
#    Given an input array, return all unique values in an array.
#-------------------------------------------------------------------
   sub uniq {
      my %seen;
      return grep { !$seen{$_}++ } @_;
   }



#--------------------
#  Main begins here 
#--------------------

#--------------------------------
#  load command line argument(s)
#--------------------------------
my $dir   = '';    # directory to be cleaned up (~/nbns/imgn/NET/RUN/monitor/pngs)
my $ncyc  = 20;    # default number of cycles to keep
my $sdirs = './';  # if unspecified then $dir is the target for cleaning

GetOptions( 'dir=s'   => \$dir,
            'sdirs=s' => \$sdirs,
            'ncyc=i'  => \$ncyc );

#------------------------------------
# verify $dir argument is a directory
#------------------------------------
unless (-d $dir) {
   die "Error: '$dir' is not a valid directory or does not exist.\n";
}

my @subdirs = split(/,/, $sdirs);

#---------------------------
# process each subdirectory
#---------------------------
foreach my $sdir ( @subdirs ) {
   my $test_dir = File::Spec->catdir($dir, $sdir);
   opendir(my $dh, $test_dir) or die "Cannot open directory '$test_dir': $!\n";

   #---------------------
   # identify file names
   #---------------------
   my @files = readdir $dh;
   #print "files: @files\n\n";
   closedir $dh;

   #----------------------
   # identify cycle times
   #----------------------
   my @times = ();
   foreach my $file ( @files ) {
      my @spl = split( '\.', $file ); 
      if( looks_like_number( $spl[1] ) && length($spl[1] ) == 10 ) {
         push( @times, $spl[1] );
      }
   }

   my @unique = ();
   if ( $#times >= 0 ) {
      @unique = sort{ $b <=> $a }( uniq( @times ));
   }

   #-------------------------------------------------
   # identify cycle times to be removed in @del_list
   #-------------------------------------------------
   my @del_list = (); 
   if( $#unique >= $ncyc ) {
      my $ii = $ncyc;
      my $end = $#unique;

      do {
         push( @del_list, $unique[$ii] );
         $ii++;
      } while $ii <= $end; 
   }

   foreach my $del ( @del_list ) {
      my $rm_cmd = "find $test_dir -type f -name '*$del*' -delete";
      system( $rm_cmd ) == 0 or die "system $rm_cmd failed: $?";
   }
}
