#!/usr/bin/env crystal

require "option_parser"

require "./combiner"

# OPTION PARSING

filters = [] of Path
silent = false
latex_output = false
beamer_output = false
output_file = "result.pdf"

OptionParser.parse do |p|
    p.banner = "Usage: marka FILE"

    p.on("-h", "--help", "Shows help") do
        puts p
        exit
    end

    p.on("-f FILTER", "--filter=FILTER", "Adds filter or filter folder to the pipeline") do |filter|
        filter = Path.new filter 

        if Dir.exists? filter
            Dir.each filter do |file|
                if file.includes? ".lua"
                    filters << Path.new file
                end
            end
        elsif File.exists? filter
            filters << filter
        else
            STDERR.puts "The filter \"#{filter}\" is neither a file nor a folder"
            exit 1
        end
    end
    
    p.on("-s", "--silent", "Disables printing status messages") do
        silent = true
    end
    
    p.on("-l", "--latex", "Outputs latex instead of rending to a pdf file") do
        latex_output = true
    end
    
    p.on("-b", "--beamer", "Outputs in beamer-mode") do
        beamer_output = true
    end
    
    p.on("-o FILE", "--output=FILE", "Sets the file that's rendered to (default: result.pdf)") do |file|
        output_file = file
    end
    
    p.invalid_option do |f|
        STDERR.puts "No flag called #{f}"
        STDERR.puts p
        exit 2
    end
end


if ARGV.size != 1
    STDERR.puts "The only positional argument should be the FILE to render but #{ARGV.size} arguments were given"
    exit 3
end


# RENDERING

target = ARGV[0]
puts "Running Combiner on #{target}" if ! silent
begin
    input = cat_file target
rescue ex : CompileException
    STDERR.puts ex.error
    ex.stack.each do |s|
        STDERR.puts "in #{s[:file]}:#{s[:line]}"
    end
    exit 4
end


add_bib = File.exists? "bibliography.bib"
#if ! (/# Bibliography/ =~ input) && /\[@/ =~ input
if add_bib
    puts "Adding bibliography header" if ! silent
    input += "\n# Bibliography\n"
end

puts "Running Pandoc" if ! silent
pipe = IO::Memory.new input
if latex_output
    output = "--to=latex"
else
    output = "--output=./#{output_file}"
end

args = [
    output,
    "--fail-if-warning",
    "--standalone",
] + filters.map do |f|
    "--lua-filter=#{f}"
end

if File.exists? "meta.yml"
    args << "--metadata-file=meta.yml"
end
    
if add_bib
    args << "--bibliography=./bibliography.bib"
    args << "--citeproc"
end

if beamer_output
    args << "--to=beamer"
end

proc = Process.new(
	"pandoc",
	args,
	input: pipe,
	error: Process::Redirect::Inherit,
	output: Process::Redirect::Inherit,
)
s = proc.wait
if !s.success?
    STDERR.puts "Pandoc failed with status: #{s.exit_code}"
    exit 2
end

