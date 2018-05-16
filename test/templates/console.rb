# Start REPL with M-x inf-ruby
require 'liquid'

template = '{% if false %} Rodman {% else %} Pippen {% else %} bad behavior {% endif %}'

Liquid::Template.error_mode = :strict

Liquid::Template.parse(template).render()
