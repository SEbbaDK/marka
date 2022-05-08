#!/usr/bin/env crystal

require "option_parser"
require "inotify"

require "./marka"
require "./explorer"


# OPTION PARSING
watch_mode = false
options_file = nil
marka_opts = MarkaOpts.new

OptionParser.parse do |p|
    p.banner = "Usage: marka FILE"

    p.on("-h", "--help", "Shows help") do
        puts p
        exit
    end

    p.on("-f FILTER", "--filter=FILTER", "Adds filter or filter folder to the pipeline") do |filter|
        filter = Path.new filter 
        marka_opts.filters = [] of Path if marka_opts.filters.nil?

        if Dir.exists? filter
            Dir.each filter do |file|
                if file.includes? ".lua"
                    marka_opts.filters.not_nil! << (filter / Path.new file)
                end
            end
        elsif File.exists? filter
            marka_opts.filters.not_nil! << filter
        else
            STDERR.puts "The filter \"#{filter}\" is neither a file nor a folder"
            exit 1
        end
    end
    
    p.on("-v", "--verbose", "Enables printing status messages") do
        marka_opts.silent = false
    end
    
    p.on("-l", "--latex", "Outputs latex instead of rending to a pdf file") do
        marka_opts.latex_output = true
    end
    
    p.on("-b", "--beamer", "Outputs in beamer-mode") do
        marka_opts.beamer_output = true
    end
    
    p.on("-o FILE", "--output=FILE", "Sets the file that's rendered to (default: result.pdf)") do |file|
        marka_opts.output_file = Path.new file
    end
    
    p.on("-w", "--watch", "Monitor all files included by FILE for changes and rerender automatically") do
        watch_mode = true
    end
    
    p.on("--pandoc=OPTION", "Pass an option to pandoc (ie --pandoc=--pdf-engine=xelatex). This can also be handled via the meta.yml method, which is more shareable and recommended.") do |option|
        marka_opts.extra_pandoc_args = [] of String if marka_opts.extra_pandoc_args.nil?
        marka_opts.extra_pandoc_args.not_nil! << option
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
marka_opts.bibliography = bib if File.exists? bib

meta = target.sibling "meta.yml"
marka_opts.meta_file = meta if File.exists? meta
puts "Found meta file at #{meta}" unless marka_opts.meta_file.nil? || marka_opts.silent

options = target.sibling "options.yml"
if File.exists? options
    puts "Found options file at #{options}" unless marka_opts.silent
    marka = Marka.new (MarkaOpts.default + MarkaOpts.from_file(options) + marka_opts)
else
    marka = Marka.new (MarkaOpts.default + marka_opts)
end


def render(m : Marka, t)
    
    begin
        result = m.render t
    rescue ex : Combiner::CompileException
        STDERR.puts ex.stacked_error
        return 1
    rescue ex : UnsupportedVariable
        STDERR.puts ex.to_s
        return 2
    end
    
    if !result.success?
        STDERR.puts "Pandoc failed with status: #{result.exit_code}"
        return 3
    end
    
    return 0
end

unless watch_mode
    exit (render marka, target)
else
    while true
        render marka, target

        files = [ target ] + Explorer.explore target
        
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

