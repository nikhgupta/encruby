#!/usr/bin/env ruby

       #       I have added some weird comments in this file,

  #

  # which can be multiline, and should be preserved by the encryptor.

#
  #          
#         
        #   a
   #   
#
         #   

   print "Hello"

# This comment will be encrypted by Encruby.

print " world!"

data1 = %q{"some data 'that has quotes'!"}
data2 = ' "whatever \"\" else"'
data3 = " and '\"more\"'"
print "\n#{:a}#{data1}#{data2}#{data3}"

   #
   # so will this be.
