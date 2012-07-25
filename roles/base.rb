name 'base'
description 'Base role'
runlist "recipe[apt]", "recipe[users]", "recipe[nginx]"
