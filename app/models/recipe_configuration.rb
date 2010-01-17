class RecipeConfiguration < ConfigurationParameter
  belongs_to :recipe
  
  validates_presence_of :recipe
  validates_uniqueness_of(:name, :scope=>:recipe_id)
  
  # Gets the list of configurations needed by the recipes loaded by a particular stage and task
  named_scope :required_for_task, lambda { |array|
    {:joins=>",recipes_stages", :conditions=>"configuration_parameters.recipe_id = recipes_stages.recipe_id && recipes_stages.stage_id = #{array[0].id} && (configuration_parameters.recipe_scope LIKE '%#{array[1].gsub(':','%')}%' || configuration_parameters.recipe_scope = '{}')"}
  }
  
  def value_requirements
    if valid_answers && valid_answers.is_a?(Array)
      sentence = sentence+"(#{valid_answers.join('|')})"
    end
    
    if valid_type
      sentence = sentence+", your answer has to be a "+valid_type.to_s
    end
    
  end
  
  def validate
    return if self.new_record? || validations.nil?
    requirements = eval(validations)
    valid_answers = requirements[:valid_answers]
    valid_type = requirements[:valid_type]    
    
    # Is the value one of the ones allowed?
    errors.add(:value, 'has to be in '+valid_answers.inspect) if(valid_answers && !valid_answers.collect{|a| a.to_s}.include?(value))
    
    # Is the value too long?
    errors.add(:value, 'has to be shorter than '+requirements[:max_length].to_s+' caracters') if requirements[:max_length] && value.size > requirements[:max_length]
    
    # Is the value of the right type?
    if valid_type == :numeric
      if value.to_i.to_s == value
        # Is it too little?
        if(requirements[:greater_than] && value.to_i <= requirements[:greater_than].to_i)
          errors.add(:value,'has to be greater than '+requirements[:greater_than])
          # or too big?
        elsif(requirements[:lower_than] && value.to_i >= requirements[:lower_than].to_i)
          errors.add(:value,'has to be lower than '+requirements[:greater_than])
        end
      else
        errors.add(:value, 'has to be '+valid_type.to_s)
      end
    end
  end    
end
