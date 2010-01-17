class DeploymentsController < ApplicationController
  
  before_filter :load_stage
  before_filter :ensure_deployment_possible, :only => [:new, :create]
  
  # GET /projects/1/stages/1/deployments
  # GET /projects/1/stages/1/deployments.xml
  def index
    @deployments = @stage.deployments
    
    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @deployments.to_xml }
    end
  end
  
  # GET /projects/1/stages/1/deployments/1
  # GET /projects/1/stages/1/deployments/1.xml
  def show
    @deployment = @stage.deployments.find(params[:id])
    set_auto_scroll
    
    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @deployment.to_xml }
      format.js { render :partial => 'status.html.erb' }
    end
  end
  
  # GET /projects/1/stages/1/deployments/new
  def new
    @deployment = @stage.deployments.new
    @deployment.task = params[:task]
    if params[:repeat]
      @original = @stage.deployments.find(params[:repeat])
      @deployment = @original.repeat
    end
    @stage_prompt_configurations = @stage.prompt_configurations
    @recipe_configuration_parameters = RecipeConfiguration.required_for_task [@stage, @deployment.task]
  end
  
  # POST /projects/1/stages/1/deployments
  # POST /projects/1/stages/1/deployments.xml
  def create
    @deployment = Deployment.new
    respond_to do |format|
      ok,stage_parameters,recipe_parameters = check_and_extract_parameters
      if ok && populate_deployment_and_fire
        @deployment.deploy_in_background!
        format.html { redirect_to project_stage_deployment_url(@project, @stage, @deployment)}
        format.xml  { head :created, :location => project_stage_deployment_url(@project, @stage, @deployment) }
      else
        @deployment.clear_lock_error
        @deployment.task = params[:task]
        if params[:repeat]
          @original = @stage.deployments.find(params[:repeat])
          @deployment = @original.repeat
        end
        @stage_prompt_configurations = stage_parameters
        @recipe_configuration_parameters = recipe_parameters
        unless ok
          @stage_prompt_configurations.each do |conf|
            @deployment.errors.add('base', "Please fill out the parameter '#{conf.name}'") unless !@deployment.prompt_config.blank? && !@deployment.prompt_config[conf.name.to_sym].blank?
          end
        end
        format.html { render :action => "new" }
        format.xml  { render :xml => @deployment.errors.to_xml }
      end
    end
  end
  
  # GET /projects/1/stages/1/deployments/latest
  def latest
    @deployment = @stage.deployments.find(:first, :order => "created_at desc")
    
    respond_to do |format|
      format.html { render :action => "show"}
      format.xml do
        if @deployment
          render :xml => @deployment.to_xml
        else
          render :status => 404, :nothing => true
        end
      end
    end
  end
  
  # POST /projects/1/stages/1/deployments/1/cancel
  def cancel
    redirect_to "/" and return unless request.post?
    @deployment = @stage.deployments.find(:first, :order => "created_at desc")
    
    respond_to do |format|
      begin
        @deployment.cancel!
        
        flash[:notice] = "Cancelled deployment by killing it"
        format.html { redirect_to project_stage_deployment_url(@project, @stage, @deployment)}
        format.xml  { head :ok }
      rescue => e
        flash[:error] = "Cancelling failed: #{e.message}"
        format.html { redirect_to project_stage_deployment_url(@project, @stage, @deployment)}
        format.xml  do
          @deployment.errors.add("base", e.message)
          render :xml => @deployment.errors.to_xml 
        end
      end
    end
  end
  
  protected
  def ensure_deployment_possible
    if current_stage.deployment_possible?
      true
    else
      respond_to do |format|  
        flash[:error] = 'A deployment is currently not possible.'
        format.html { redirect_to project_stage_url(@project, @stage) }
        format.xml  { render :xml => current_stage.deployment_problems.to_xml }
        false
      end
    end
  end
  
  def set_auto_scroll
    if params[:auto_scroll].to_s == "true"
      @auto_scroll = true
    else
      @auto_scroll = false
    end
  end
  
  # Check that every parameter is valid
  # Extracting the parameters is needed for the following reasons :
  # - they come as {id=>value} instead of {name=>value}, which is needed by ActiveRecord to create objects
  # - Stage/Deployment params come mixed with Recipe params, we then need to split them.
  # We "fix" the params[:deployment][:prompt_config] hash following these principles
  # so that it can be used as if nothing happened
  # Nevertheless, we have to include ALL parameters (not just "non.recipe" ones)
  # into params[:deployment][:prompt_config], otherwise they won't be passed to Capistrano
  def check_and_extract_parameters
    ok = true
    stage_parameters  = Array.new
    recipe_parameters = Array.new
    
    new_prompt_config = Hash.new
    
    params[:deployment][:prompt_config].each do |id,value|
      value = value[:value]
      p = ConfigurationParameter.find(id)
      p.value = value
      if p.is_a? RecipeConfiguration
        recipe_parameters << p
      else
        stage_parameters << p
      end
      new_prompt_config[p.name] = p.value
      ok = p.valid? && ok
    end
    params[:deployment][:prompt_config] = new_prompt_config
    return ok,stage_parameters,recipe_parameters
  end
  
  # sets @deployment
  def populate_deployment_and_fire
    return Deployment.lock_and_fire do |deployment|
      @deployment = deployment
      @deployment.attributes = params[:deployment]
      @deployment.prompt_config = params[:deployment][:prompt_config] rescue {}
      @deployment.stage = current_stage
      @deployment.user = current_user
    end
  end
  
end
