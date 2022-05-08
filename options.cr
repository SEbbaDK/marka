require "yaml"

require "./variables.cr"

OPTIONSVARS = [
	"pdf_engine",
	"template_vars",
    "filters",
    "silent",
    "latex_output",
    "beamer_output",
    "output_file",
    "bibliography",
    "meta_file",
    "extra_pandoc_args",
    "template_vars",
] of String

class UnsupportedVariable < Exception
end
    
class MarkaOpts
    property pdf_engine : String | Nil
    property filters : Array(Path) | Nil
    property silent : Bool | Nil
    property latex_output : Bool | Nil
    property beamer_output : Bool | Nil
    property output_file : Path | Nil
    property bibliography : Path | Nil
    property meta_file : Path | Nil
    property extra_pandoc_args : Array(String) | Nil
    property template_vars : Hash(String, String | Array(String)) | Nil
    
    def self.default : MarkaOpts
        opts = self.new
        
        opts.pdf_engine = nil
        opts.filters = [] of Path
        opts.silent = true
        opts.latex_output = false
        opts.beamer_output = false
        opts.output_file = Path.new "result.pdf"
        opts.bibliography = nil
        opts.meta_file = nil
        opts.extra_pandoc_args = [] of String
        opts.template_vars = {} of String => String | Array(String)
        
        opts
    end
    
    def self.from_file(file) : MarkaOpts
        o = File.open(file) do |content|
            YAML.parse content
        end
        
        h = o.as_h
        h.each_key do |key|
            unless Variables::METAVARS.includes?(key)|| OPTIONSVARS.includes?(key)
                raise UnsupportedVariable.new "Given option »#{key}« is not a valid key for Marka or Pandoc.\nIf this is a template variable, add it under the 'templatevars' variable."
            end
        end
        
        opts = self.new
        
        h["pdf_engine"]?.try  do |v|
            opts.pdf_engine = v.as_s
        end
        h["filters"]?.try  do |v|
            opts.filters = v.as_a.map { |s| Path.new s.as_s }
        end
        h["silent"]?.try  do |v|
            opts.silent = v.as_bool
        end
        h["latex_output"]?.try  do |v|
            opts.latex_output = v.as_bool
        end
        h["beamer_output"]?.try  do |v|
            opts.beamer_output = v.as_bool
        end
        h["output_file"]?.try  do |v|
            opts.output_file = Path.new v.as_s
        end
        h["bibliography"]?.try  do |v|
            opts.bibliography = Path.new v.as_s
        end
        h["meta_file"]?.try  do |v|
            opts.meta_file = Path.new v.as_s
        end
        h["extra_pandoc_args"]?.try  do |v|
            opts.extra_pandoc_args = v.as_a.map { |s| s.as_s }
        end
        h["template_vars"]?.try do |tv|
            opts.template_vars = tv.as_h.map do |k,v|
                { k.as_s, k.as_s? || k.as_a.map { |v| v.as_s } }
            end.to_h
        end
        
        opts
    end
    
    def +(other : MarkaOpts)
        @filters = other.filters                      unless other.filters.nil?
        @silent = other.silent                        unless other.silent.nil?
        @latex_output = other.latex_output            unless other.latex_output.nil?
        @beamer_output = other.beamer_output          unless other.beamer_output.nil?
        @output_file = other.output_file              unless other.output_file.nil?
        @bibliography = other.bibliography            unless other.bibliography.nil?
        @meta_file = other.meta_file                  unless other.meta_file.nil?
        # TODO: This should combine the array
        @extra_pandoc_args = other.extra_pandoc_args  unless other.extra_pandoc_args.nil?
        # TODO: This should combine the hash
        @template_vars = other.template_vars          unless other.template_vars.nil?
        self
    end
end

