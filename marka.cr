require "./combiner"

class Marka
    property filters = [] of Path
    property silent = true
    property latex_output = false
    property beamer_output = false
    property output_file = "result.pdf"
    property bibliography : Path | Nil = nil
    property meta : Path | Nil = nil
    property extra_pandoc_args = [] of String
    
    def render(file)
        puts "Running Combiner on #{file}" unless silent
        input = Combiner.combine file

        if ! bibliography.nil?
            puts "Adding bibliography header" unless silent
            input += "\n# Bibliography\n"
        end
        
        puts "Running Pandoc" unless silent
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
        ] + extra_pandoc_args + filters.map do |f|
            "--lua-filter=#{f}"
        end

        if ! meta.nil?
            args << "--metadata-file=#{meta}"
        end
            
        if ! bibliography.nil?
            args << "--bibliography=#{bibliography}"
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
        proc.wait
    end
end

