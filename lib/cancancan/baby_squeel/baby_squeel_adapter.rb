# frozen_string_literal: true
class CanCanCan::BabySqueel::BabySqueelAdapter < CanCan::ModelAdapters::AbstractAdapter
  include CanCanCan::BabySqueel::ExpressionCombinator

  ALWAYS_TRUE = CanCanCan::BabySqueel::ExpressionCombinator::ALWAYS_TRUE
  ALWAYS_FALSE = CanCanCan::BabySqueel::ExpressionCombinator::ALWAYS_FALSE

  def self.for_class?(model_class)
    model_class <= ActiveRecord::Base
  end

  def self.override_condition_matching?(subject, name, _)
    match_relation?(subject, name) || match_enum?(subject, name)
  end

  def self.matches_condition?(subject, name, value)
    if match_relation?(subject, name)
      matches_relation?(subject, name, value)
    elsif match_enum?(subject, name)
      matches_enum?(subject, name, value)
    else
      false
    end
  end

  # Overrides condition matching for enums.
  def self.match_enum?(subject, name)
    klass = subject.class
    klass.respond_to?(:defined_enums) && klass.defined_enums.include?(name.to_s)
  end
  private_class_method :match_enum?

  # Overrides condition matching for enums.
  def self.matches_enum?(subject, name, value)
    # Get the mapping from enum strings to values.
    enum = subject.class.public_send(name.to_s.pluralize)

    # Get the value of the attribute as an integer.
    attribute = enum[subject.public_send(name)]

    # Check to see if the value matches the condition.
    value.is_a?(Enumerable) ? value.include?(attribute) : attribute == value
  end
  private_class_method :matches_enum?

  def self.match_relation?(subject, name)
    subject_attribute = subject.public_send(name)
    subject_attribute.is_a?(ActiveRecord::Relation) && !subject_attribute.loaded
  end
  private_class_method :match_relation?

  def self.matches_relation?(subject, name, value)
    relation = subject.public_send(name)
    klass = subject.class.reflect_on_association(name).klass
    join_list = nil

    scope = relation.where.has do
      expression, join_list = CanCanCan::BabySqueel::ExpressionBuilder.build(self, klass, :eq, value)
      expression
    end

    add_joins_to_scope(scope, join_list, :inner).any?
  end
  private_class_method :matches_relation?

  def database_records
    # TODO: Handle overridden scopes.
    relation.distinct
  end

  # Builds a relation, outer joined on the provided associations.
  #
  # @param [ActiveRecord::Relation] scope The current scope to add the joins to.
  # @param [Array<Array<Symbol>>] joins The set of associations to outer join with.
  # @param [Symbol] join_type The type of join; defaults to outer joins.
  # @return [ActiveRecord::Relation] The built relation.
  def self.add_joins_to_scope(scope, joins, join_type = :outer)
    joins.reduce(scope) do |result, join|
      result.joining do
        join.reduce(self) do |relation, association|
          relation = relation.__send__(association)
          relation = relation.__send__(join_type) unless join_type == :inner
          relation
        end
      end
    end
  end
  private_class_method :add_joins_to_scope

  private

  # Builds a relation that expresses the set of provided rules.
  #
  # The required Squeel expression is built, then the joins which are necessary to satisfy the
  # expressions are added to the query scope.
  def relation
    adapter = self
    join_list = nil
    scope = @model_class.where(nil).where.has do
      expression, join_list = adapter.send(:build_accessible_by_expression, self)
      expression
    end

    add_joins_to_scope(scope, join_list)
  end

  # @see CanCanCan::BabySqueel::BabySqueelAdapter.add_joins_to_scope
  def add_joins_to_scope(*args)
    self.class.send(:add_joins_to_scope, *args)
  end

  # This builds Squeel expression for each rule, and combines the expression with those to the left
  # using a fold-left.
  #
  # The rules provided by Cancancan are in reverse order, i.e. the lowest priority rule is first.
  #
  # @param squeel The Squeel scope.
  # @return [Array<(Squeel::Nodes::Node, Array<Array<Symbol>>)>] A tuple containing the Squeel
  #   expression, as well as an array of joins which the Squeel expression must be joined to.
  def build_accessible_by_expression(squeel)
    @rules.reverse.reduce([ALWAYS_FALSE, []]) do |(left_expression, joins), rule|
      combine_expression_with_rule(squeel, left_expression, joins, rule)
    end
  end

  # Combines the given expression with the new rule.
  #
  # @param squeel The Squeel scope.
  # @param left_expression The Squeel expression for all preceding rules.
  # @param [Array<Array<Symbol>>] joins An array of joins which the Squeel expression must be
  #   joined to.
  # @param [CanCan::Rule] rule The rule being added.
  # @return [Array<(Squeel::Nodes::Node, Array<Array<Symbol>>)>] A tuple containing the Squeel
  #   expression, as well as an array of joins which the Squeel expression must be joined to.
  def combine_expression_with_rule(squeel, left_expression, joins, rule)
    right_expression, right_expression_joins = build_expression_from_rule(squeel, rule)
    operator = rule.base_behavior ? :or : :and

    expression, joins = combine_squeel_expressions(left_expression, joins, operator, right_expression,
                                                   right_expression_joins)

    squeel._scope = add_joins_to_scope(squeel._scope, joins)
    [expression, joins]
  end

  # Builds a Squeel expression representing the rule's conditions.
  #
  # @param squeel The Squeel scope.
  # @param [CanCan::Rule] rule The rule being built.
  # @return [Array<(Squeel::Nodes::Node, Array<Array<Symbol>>)>] A tuple containing the Squeel
  #   expression representing the rule's conditions, as well as an array of joins which the Squeel
  #   expression must be joined to.
  def build_expression_from_rule(squeel, rule)
    if rule.conditions.empty?
      [rule.base_behavior ? ALWAYS_TRUE : ALWAYS_FALSE, []]
    else
      comparator = rule.base_behavior ? :eq : :not_eq
      CanCanCan::BabySqueel::ExpressionBuilder.build(squeel, @model_class, comparator, rule.conditions)
    end
  end
end
