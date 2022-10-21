require 'rubocop'
require 'rubocop-ast'
require 'pry'

class Rule < Parser::AST::Processor
  include RuboCop::AST::Traversal
  include RuboCop::Cop::RangeHelp

  def initialize(rewriter, source)
    @rewriter = rewriter
    @processed_source = source
  end

  def create_range(begin_pos, end_pos)
    Parser::Source::Range.new(@rewriter.source_buffer, begin_pos, end_pos)
  end
end

# Replace top-level module and last end
class ReplaceBaseModule < Rule
  def on_class(node)
    return if node.parent_class

    check_style(node, node.body)
  end

  def on_module(node)
    return if node.parent
    binding.pry
    check_style(node, node.body)
  end

  def check_style(node, body)
    # parent_class_name = node.descendants.find { |d| d.class_type? }.parent_class.const_name
    # return if parent_class_name.include? 'Trailblazer'
    return if node.identifier.children[0]&.cbase_type?
    parent = node.parent
    return if parent&.class_type? || parent&.module_type?
    return unless needs_compacting? body
    autocorrect node
  end

  def needs_compacting?(body)
    body && %i[module class].include?(body.type)
  end

  def autocorrect(node)
    return if node.class_type? && node.parent_class
    compact_node(node)
    remove_end(node.body)
    unindent(node)
  end

  def compact_node(node)
    range = create_range(node.loc.keyword.begin_pos, node.body.loc.name.end_pos)
    @rewriter.replace(range, compact_replacement(node))
  end

  def compact_replacement(node)
    "#{node.body.type} #{compact_identifier_name(node)}"
  end

  def compact_identifier_name(node)
    "#{node.identifier.const_name}::" \
      "#{node.body.children.first.const_name}"
  end

  def remove_end(body)
    remove_begin_pos = body.loc.end.begin_pos - leading_spaces(body).size
    adjustment = @processed_source.raw_source[remove_begin_pos] == ';' ? 0 : 1
    range = create_range(remove_begin_pos, body.loc.end.end_pos + adjustment)

    @rewriter.remove(range)
  end

  def unindent(node)
    return if node.body.children.last.nil?
    configured_indentation_width = 2
    column_delta = configured_indentation_width - leading_spaces(node.body.children.last).size
    return if column_delta.zero?

    RuboCop::Cop::AlignmentCorrector.correct(@rewriter, @processed_source, node, column_delta)
  end

  def leading_spaces(node)
    node.source_range.source_line[/\A\s*/]
  end
end

# class ReplaceBrowserMethodNames < Rule
  # def on_send(node)
    # replace_method = case node.method_name
                     # when :at_xpath then 'find'
                     # when :xpath then 'all'
                     # when :inner_text then 'text'
                     # else nil
                     # end
    # @rewriter.replace(node.loc.selector, replace_method) if replace_method
  # end
# end

# replace e.g. a.blank? ? nil : b with just b since the blank? is
# covered by base code
# class ReplaceBlankChecks < Rule
  # def on_send(node) # we could have used on_if instead here and checked children
    # return if node.method_name != :blank? || node.sibling_index != 0

    # siblings = node.parent.children
    # if siblings.size == 3 && siblings[1].nil_type? && siblings[2].send_type?
      # @rewriter.replace(node.parent.loc.expression, siblings[2].source)
    # end
  # end
# end

# Main method.
def process_file(file, rule_classes=Rule.subclasses)
  return unless File.exist?(file)
  code = File.read(file)
  rule_classes.each do |rule_class|
    code = process_rule(rule_class, code)
  end
  File.open(file, "w") { |f| f.puts code }
end

def process_rule(rule_class, code)
  source = RuboCop::ProcessedSource.new(code, 3.0)
  source_buffer = source.buffer
  rewriter = Parser::Source::TreeRewriter.new(source_buffer)
  rule = rule_class.new(rewriter, source)
  source.ast.each_node { |n| rule.process(n) }
  rewriter.process
end

def files_to_process
  file = File.join("#{Dir.home}/Github/luma_app/app/concepts/luma_method/operation/**", '*.rb')
  Dir.glob(file)
end

files_to_process.each do |file_name|
  process_file file_name
end
