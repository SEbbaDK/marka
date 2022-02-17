module Explorer
    def self.explore(file : Path)
        files = [] of Path
        File.each_line file do |line|
            match = /€\[([^]]+)\]/.match(line)
            if ! match.nil?
                path = Path[match[1]]
                puts "Found #{path}"
                if ! path.absolute?
                    path = (Path[file.dirname] / path).normalize
                end
                puts "Adding as #{path}"
                files << path
                files += explore(path)
            end
        end
        files
    end
end

