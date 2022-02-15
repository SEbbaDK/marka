#!/usr/bin/env crystal

class CompileException < Exception
    getter error, stack
    
    def initialize(error : String)
        @error = error
        @stack = [] of NamedTuple(file: String, line: Int32)
    end
    
    def add_stack(file : String, line : Int32) : CompileException
        @stack << { file: file, line: line }
        self
    end
end

def cat_file(filename)
    result = ""
    l = 0
    
    File.each_line filename do |line|
    	begin
        	result += expand_line(line) + "\n"
    	rescue ex : CompileException
        	raise ex.add_stack filename, l
    	end
        l += 1
    end
    
    return result
end

def cat_file_from_to(from, to, filename, include_edges = true)
    result = ""
    in_block = false
    found = false
    l = 0
    
    File.each_line filename do |line|
        begin
            stripline = line.strip()
            in_block = true if stripline == from
        
            result += expand_line(line) + '\n' if in_block
            found = true if in_block
            
            in_block = false if stripline == to
        rescue ex : CompileException
            raise ex.add_stack filename, l
        end
        l += 1
    end
    
    if found == false
        raise CompileException
        	.new("Matchgroup searching for »#{from}« to »#{to}« didn't find anything")
        	.add_stack filename, l
    end
    
    return result
end

def expand_line(line)
    md = /€\[([^]]+)\](<([^>]+)>)?/.match(line)
    
    if md.nil?
        return line
    else
        filename = md[1]
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

# CLI PARTS
if ARGV.size != 1
    STDERR.puts "Give the target file as the single parameter"
    exit 1
end

target = ARGV[0]
begin
    puts cat_file target
rescue ex : CompileException
    STDERR.puts ex.error
    ex.stack.each do |s|
        STDERR.puts "in #{s[:file]}:#{s[:line]}"
    end
end

