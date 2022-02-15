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

    def cat_file_from_to(from, to, file : Path, include_edges = true)
        result = ""
        in_block = false
        found = false
        l = 0
        
        File.each_line file do |line|
            begin
                stripline = line.strip()
                in_block = true if stripline == from
            
                result += expand_line(file, line) + '\n' if in_block
                found = true if in_block
                
                in_block = false if stripline == to
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
                
            elsif selector =~ /^start-end/
                split = selector.split("|")
                
                if split.size != 3
                    raise CompileException.new "Wrong number of blocks for start-end selector: #{selector} into #{split}"
                end
                return cat_file_from_to split[1], split[2], filename
                
            elsif selector =~ /^from-to/
                split = selector.split("|")
                
                if split.size != 3
                    raise CompileException.new "#{line}: Wrong number of blocks for from-to selector: #{selector} into #{split}"
                end
                return cat_file_from_to split[1], split[2], filename, include_edges = false
                
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
