class RecipeConfigurationsController < ApplicationController
  # GET /recipes/1/recipe_configurations/1;edit
  def edit
    @recipe = Recipe.find(params[:recipe_id])
    @configuration = @recipe.configuration_parameters.find(params[:id])
  end
  
  
  # PUT /recipes/1/recipe_configurations/1
  # PUT /recipes/1/recipe_configurations/1.xml
  def update
    @recipe = Recipe.find(params[:recipe_id])
    @configuration = @recipe.configuration_parameters.find(params[:id])
    
    respond_to do |format|
      
      # Recipe_scope is not mass-assignable
      if params[:configuration].key? :recipe_scope
        @configuration.recipe_scope = params[:configuration][:recipe_scope]
        params[:configuration].delete :recipe_scope
      end
      
      # validations is not mass-assignable
      if params[:configuration].key? :validations
        @configuration.validations = params[:configuration][:validations]
        params[:configuration].delete :validations
      end
      
      if @configuration.update_attributes(params[:configuration])
        flash[:notice] = 'RecipeConfiguration was successfully updated.'
        format.html { redirect_to recipe_url(@recipe) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @configuration.errors.to_xml }
      end
    end
  end
  
  # DELETE /recipes/1/recipe_configurations/1
  # DELETE /recipes/1/recipe_configurations/1.xml
  def destroy
    @recipe = Recipe.find(params[:recipe_id])
    @configuration = @recipe.configuration_parameters.find(params[:id])
    @configuration.destroy
    
    respond_to do |format|
      flash[:notice] = 'RecipeConfiguration was successfully deleted.'
      format.html { redirect_to recipe_url(@recipe) }
      format.xml  { head :ok }
    end
  end
end
