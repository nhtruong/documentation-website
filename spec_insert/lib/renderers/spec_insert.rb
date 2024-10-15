# frozen_string_literal: true

require_relative 'base_mustache_renderer'
require_relative '../insert_arguments'
require_relative 'parameter_table_renderer'
require_relative 'paths_and_methods'
require_relative '../components/action'

# Class to render spec insertions
class SpecInsert < BaseMustacheRenderer
  COMPONENTS = Set.new(%w[query_params path_params paths_and_http_methods]).freeze
  self.template_file = './lib/renderers/templates/spec_insert.mustache'

  # @param [Array<String>] arg_lines the lines between <!-- doc_insert_start and -->
  def initialize(arg_lines)
    super
    @args = InsertArguments.new(arg_lines)
    @action = Action.actions[@args.api]
    raise ArgumentError, "API Action not found: #{@args.api}" unless @action
  end

  def arguments
    @args.raw.map { |key, value| { key:, value: } }
  end

  def content
    case @args.component.to_sym
    when :query_parameters, :query_params
      params = @action.arguments.select { |arg| arg.location == ArgLocation::QUERY }
      ParameterTableRenderer.new(params, @args).render
    when :path_parameters, :path_params
      params = @action.arguments.select { |arg| arg.location == ArgLocation::PATH }
      ParameterTableRenderer.new(params, @args).render
    when :paths_and_http_methods
      PathsAndMethods.new(@action).render
    else
      raise ArgumentError, "Invalid component: #{@args.component}"
    end
  end
end
