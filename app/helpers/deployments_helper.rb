module DeploymentsHelper
  
  def js_modifier validations, field_to_modify
    return if validations == '{}' || validations.nil?
    validations =  eval(validations)
    if validations.key? :only_if
      field = validations[:only_if].keys[0]
      value = validations[:only_if].values[0]
      return <<-"EOF"
      <script type="text/javascript">
      var field_id = $('#{field}').children[4].id;
      document.observe("dom:loaded", function() {
        var value = $(field_id);
        if (value.toString() !=  '#{value}') {
            $('#{field_to_modify}').hide();
          };
        });
    //<![CDATA[
        new Form.Element.EventObserver(field_id, function(element, value) 
        {
          if(value.toString() == '#{value}'){
              Effect.Appear('#{field_to_modify}');
              $('#{field_to_modify}').show().highlight();
            }
          else{
              Effect.Fade('#{field_to_modify}');
            }
          }
          )
    //]]>
          </script>
          EOF
        end
      end
      
      def input_type(name)
        if name.match(/password/)
      "password"
        else
      'text'
        end
      end
      
      def if_disabled_host?(host, text)
       (@deployment.excluded_host_ids.include?(host.id) ? text : '' rescue '')
      end
      
      def if_enabled_host?(host, text)
       (@deployment.excluded_host_ids.include?(host.id) ? '' : text rescue text)
      end
    end
