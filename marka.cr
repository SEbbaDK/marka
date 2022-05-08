require "./combiner"
require "./options"

def unnil(a : Array(String) | Nil)
    a || [] of String
end

def unnil(a : Array(Path) | Nil)
    a || [] of Path
end

class Marka
    opts : MarkaOpts
    def initialize(opts : MarkaOpts)
        @opts = opts
    end
    
    def render(file)
        puts "Running Combiner on #{file}" unless @opts.silent
        input = Combiner.combine file

        if ! @opts.bibliography.nil?
            puts "Adding bibliography header" unless @opts.silent
            input += "\n# Bibliography\n"
        end
        
        puts "Running Pandoc" unless @opts.silent
        pipe = IO::Memory.new input
        if @opts.latex_output
            output = "--to=latex"
        else
            output = "--output=./#{@opts.output_file}"
        end

        args = [
            output,
            "--fail-if-warning",
            "--standalone",
        ] + unnil(@opts.extra_pandoc_args) + unnil(@opts.filters).map do |f|
            "--lua-filter=#{f}"
        end

        if ! @opts.meta_file.nil?
            args << "--metadata-file=#{@opts.meta_file}"
        end
        
        if ! @opts.bibliography.nil?
            args << "--bibliography=#{@opts.bibliography}"
            args << "--citeproc"
        end

        if @opts.beamer_output
            args << "--to=beamer"
        end

        proc = Process.new(
            "pandoc",
            args,
            input: pipe,
            error: Process::Redirect::Inherit,
            output: Process::Redirect::Inherit,
        )
        proc.wait
    end
end

