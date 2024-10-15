# frozen_string_literal: true

require_relative 'base_mustache_renderer'
require_relative 'parameter_table_renderer'
require_relative 'paths_and_methods'
require_relative '../components/action'

# Class to render spec insertions
class SpecInsert < BaseMustacheRenderer
  COMPONENTS = Set.new(%w[query_params path_params paths_and_http_methods]).freeze
  self.template_file = './lib/renderers/templates/spec_insert.mustache'

  # @param [Array<Hash>] args
  def initialize(args)
    super
    @args = args
    @action = Action.actions[args['api']]
    raise ArgumentError, "API Action not found: #{args['api']}" unless @action
  end

  def arguments
    @args.map do |k, v|
      { key: k,
        value: v.is_a?(Array) ? v.join(', ') : v }
    end
  end

  def content
    columns = @args['columns']
    pretty = parse_boolean(@args['pretty'], default: false)
    include_global = parse_boolean(@args['include_global'], default: false)
    include_deprecated = parse_boolean(@args['include_deprecated'], default: true)

    case @args['component']
    when 'query_params', 'query_parameters'
      arguments = @action.arguments.select { |arg| arg.location == ArgLocation::QUERY }
      ParameterTableRenderer.new(arguments, columns:, include_global:, include_deprecated:, pretty:).render
    when 'path_params', 'path_parameters'
      arguments = @action.arguments.select { |arg| arg.location == ArgLocation::PATH }
      ParameterTableRenderer.new(arguments, columns:, pretty:).render
    when 'paths_and_http_methods'
      PathsAndMethods.new(@action).render
    else
      raise ArgumentError, "Invalid component: #{@args['component']}"
    end
  end

  private

  # @param [String] value
  # @param [Boolean] default value to return when nil
  def parse_boolean(value, default:)
    return default if value.nil?
    return true if value.in?(%w[true True TRUE yes Yes YES 1])
    return false if value.in?(%w[false False FALSE no No NO 0])
    raise ArgumentError, "Invalid boolean value: #{value}"
  end
end