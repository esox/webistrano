class Recipe < ActiveRecord::Base
  has_and_belongs_to_many :stages
  has_many :configuration_parameters, :dependent => :destroy, :class_name => "RecipeConfiguration", :order => 'name ASC'
  
  validates_uniqueness_of :name
  validates_presence_of :name, :body
  validates_length_of :name, :maximum => 250 
  
  attr_accessible :name, :body, :description
  
  named_scope :ordered, :order => "name ASC"
  
  before_save :add_configuration_parameters
  after_update :save_configuration_parameters # Needed because Rails doesn't do it automatically after update as it does after create.
  
  version_fu rescue nil # hack to silence migration errors when the original table is not there
  
  def validate
    check_syntax
  end
  
  def check_syntax
    return if self.body.blank?
    
    result = ""
    Open4::popen4 "ruby -wc" do |pid, stdin, stdout, stderr|
      stdin.write body
      stdin.close
      output = stdout.read
      errors = stderr.read
      result = output.empty? ? errors : output
    end
    
    unless result == "Syntax OK"
      line = $1.to_i if result =~ /^-:(\d+):/
      errors.add(:body, "syntax error at line: #{line}") unless line.nil?
    end
  rescue => e
    RAILS_DEFAULT_LOGGER.error "Error while validating recipe syntax of recipe #{self.id}: #{e.inspect} - #{e.backtrace.join("\n")}"
  end
  
  private
  
  def save_configuration_parameters
    configuration_parameters.each do |param|
      param.save
    end
  end
  
  def add_configuration_parameters
    logger.fatal body.match(/(# required configurations)(.*)(# \/required configurations)/m)[2].gsub('#','')
    lines = body.match(/(# required configurations)(.*)(# \/required configurations)/m)[2].gsub('#','').strip.split("\n")
    lines.each do |line|
      p line
      params = eval("[#{line}]")
      r = ConfigurationParameter.scoped_by_recipe_id(id).find_by_name(params[0].to_s)
      r ||= RecipeConfiguration.new
      r.name = params[0].to_s
      r.description = params[1].to_s
      r.recipe_scope = params[2].inspect
      
      if params[3]
        if params[3].key?(:prompt_on_deploy) && params[3][:prompt_on_deploy] == 1
          r.prompt_on_deploy = 1 
          params[3].delete(:prompt_on_deploy)
        end
        if params[3].key?(:default)
          r.value = params[3][:default]
          params[3].delete(:default)
        end
        r.validations = params[3].inspect
      end
      self.configuration_parameters << r 
    end
  end
end
