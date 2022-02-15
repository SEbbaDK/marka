require "./combiner"

if ARGV.size != 1
    STDERR.puts "A file to combine should be given as the only argument"
    exit 1
end

begin
    puts cat_file ARGV[1]
rescue ex : CompileException
    STDERR.puts ex.error
    ex.stack.each do |s|
        STDERR.puts "in #{s[:file]}:#{s[:line]}"
    end
    exit 4
end
