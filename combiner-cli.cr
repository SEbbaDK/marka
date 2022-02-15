#!/usr/bin/env crystal

require "./combiner"

if ARGV.size != 1
    STDERR.puts "A file to combine should be given as the only argument"
    exit 1
end

if ARGV[0] == "-h" || ARGV[0] == "--help"
    puts "USAGE: marka-combiner FILE"
    puts "Give the single FILE to combine as the input"
    exit
end

begin
    puts Combiner.combine ARGV[0]
rescue ex : Combiner::CompileException
    STDERR.puts ex.stacked_error
    exit 1
end

