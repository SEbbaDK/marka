#!/usr/bin/env crystal

module Combiner
    extend self
    
    def self.combine(filename : String | Path)
        filename = Path[filename] if filename.is_a? String
        cat_file filename
    end
    
    class CompileException < Exception
        getter error, stack
        
        def initialize(error : String)
            @error = error
            @stack = [] of NamedTuple(file: String, line: Int32)
        end
        
        def add_stack(file : Path, line : Int32) : CompileException
            @stack << { file: file.to_s, line: line }
            self
        end
        
        def stacked_error
            e = error
            stack.each do |s|
                e += "\nin #{s[:file]}:#{s[:line]}"
            end
            e
        end
    end

    def cat_file(file : Path)
        result = ""
        l = 0
        
        File.each_line file do |line|
            begin
                result += expand_line(file, line) + "\n"
            rescue ex : CompileException
                raise ex.add_stack file, l
            end
            l += 1
        end
        
        return result
    end

	enum SearchMode
		EqualitySearch
		SubStringSearch
		RegexSearch
	end
	
    def cat_file_from_to(from, to, file : Path, include_edges = true, search_mode = EqualitySearch)
        result = ""
        in_block = false
        found = false
        l = 0
        
        File.each_line file do |line|
            begin
                stripline = line.strip()
                case search_mode
                when EqualitySearch
                    in_block = true if stripline == from
                when SubStringSearch
                    in_block = true if stripline.includes? from
                when RegexSearch
                    in_block = true if stripline =~ from
                end
            
                result += expand_line(file, line) + '\n' if in_block
                found = true if in_block
                
                case search_mode
                when EqualitySearch
                    in_block = false if stripline == to
                when SubStringSearch
                    in_block = false if stripline.includes? to
                when RegexSearch
                    in_block = false if stripline =~ to
                end
            rescue ex : CompileException
                raise ex.add_stack file, l
            end
            l += 1
        end
        
        if found == false
            raise CompileException
                .new("Matchgroup searching for »#{from}« to »#{to}« didn't find anything")
                .add_stack file, l
        end
        
        return result
    end

    def expand_line(file, line)
        md = /€\[([^]]+)\](<([^>]+)>)?/.match(line)
        
        if md.nil?
            return line
        else
            filename = Path.new md[1]
            filename = (file.sibling filename).normalize unless filename.absolute?
            selector = md[3]? || "cat"
            
            if selector == "cat"
                return cat_file filename
                
            elsif selector =~ /^from-to/
                split = selector.split("|")
                
                if split.size != 3
                    raise CompileException.new "Wrong number of blocks for start-end selector: #{selector} into #{split}"
                end
                
                case split[0]
                when "from-to", "from-to-full"
                    return cat_file_from_to split[1], split[2], filename, search_mode = EqualitySearch
                when "from-to-substring"
                    return cat_file_from_to split[1], split[2], filename, search_mode = SubStringSearch
                when "from-to-regex"
                    return cat_file_from_to split[1], split[2], filename, search_mode = RegexSearch
                end
                
            elsif selector =~ /^between/
                split = selector.split("|")
                
                if split.size != 3
                    raise CompileException.new "#{line}: Wrong number of blocks for from-to selector: #{selector} into #{split}"
                end
                
                case split[0]
                when "between", "between-full"
                    return cat_file_from_to split[1], split[2], filename, search_mode = EqualitySearch, include_edges = false
                when "between-substring"
                    return cat_file_from_to split[1], split[2], filename, search_mode = SubStringSearch, include_edges = false
                when "between-regex"
                    return cat_file_from_to split[1], split[2], filename, search_mode = RegexSearch, include_edges = false
                end
                
            elsif selector =~ /^kmodule/
                split = selector.split("|")
                
                if split.size != 2
                    raise CompileException.new "#{line}: No module name given for kmodule selector: #{selector}"
                else
                    modulename = split[1]
                    return cat_file_from_to "module #{modulename}", "endmodule", filename
                end
                
            else
                raise CompileException.new "Non-valid »#{selector}« selector given"
            end
        end
end
end # module
