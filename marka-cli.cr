#!/usr/bin/env crystal

require "option_parser"
require "inotify"

require "./marka"
require "./explorer"

marka = Marka.new

# OPTION PARSING

watch_mode = false

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
                    marka.filters << (filter / Path.new file)
                end
            end
        elsif File.exists? filter
            marka.filters << filter
        else
            STDERR.puts "The filter \"#{filter}\" is neither a file nor a folder"
            exit 1
        end
    end

    p.on("-v", "--verbose", "Enables printing status messages") do
        marka.silent = false
    end
    
    p.on("-l", "--latex", "Outputs latex instead of rending to a pdf file") do
        marka.latex_output = true
    end
    
    p.on("-b", "--beamer", "Outputs in beamer-mode") do
        marka.beamer_output = true
    end
    
    p.on("-o FILE", "--output=FILE", "Sets the file that's rendered to (default: result.pdf)") do |file|
        marka.output_file = file
    end
    
    p.on("-w", "--watch", "Monitor all files included by FILE for changes and rerender automatically") do
        watch_mode = true
    end
    
    p.on("--pandoc=OPTION", "Pass an option to pandoc (ie --pandoc=--pdf-engine=xelatex). This can also be handled via the meta.yml method, which is more shareable and recommended.") do |option|
        marka.extra_pandoc_args << option
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

target = Path[ARGV[0]]

bib = target.sibling "bibliography.bib"
marka.bibliography = bib if File.exists? bib

meta = target.sibling "meta.yml"
marka.meta = meta if File.exists? meta

def render(m, t)
    
    begin
        result = m.render t
    rescue ex : Combiner::CompileException
        STDERR.puts ex.stacked_error
        return 1
    end
    
    if !result.success?
        STDERR.puts "Pandoc failed with status: #{result.exit_code}"
        return 2
    end
    
    return 0
end

unless watch_mode
    exit (render marka, target)
else
    while true
        render marka, target

        files = [ target ] + Explorer.explore target
        marka.meta.try do |m|
            files += [ m ]
        end
        
        channel = Channel(Path).new
        
        watchers = files.map do |file|
            Inotify.watch file.to_s do |event|
                if event.type.modify?
                    #puts "#{file} was modified"
                    begin
                        channel.send(file)
                    rescue Channel::ClosedError
                        # Just do nothing when the channel is closed out
                    end
                end
            end
        end
        
        change = channel.receive
        
        watchers.each do |w|
            w.close
        end
        
        channel.close
        
        puts "Rerendering because #{change} changed"
    end
end

