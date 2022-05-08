#!/usr/bin/env crystal

variables = [ "title-meta", "author-meta", "date-meta" ]
insec = false
last_empty = false

STDIN.each_line do |line|
    insec = true if line == "## Variables"
    insec = false if line == "## Typography"
    
    if insec && last_empty
        if line.size > 0 && line[0] == '`'
            line.split(", ").each{ |v| variables << v.strip '`' }
        end
    end
    
    last_empty = (line == "")
end

puts "# File was autogenerated by ./variable-finder.cr"
puts "# Do not modify manually"

puts "module Variables"
puts "  METAVARS = ["
variables.each do |l|
    puts "    \"#{l}\","
end
puts "  ] of String"
puts "end"
