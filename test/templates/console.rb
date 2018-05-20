# Start REPL with M-x inf-ruby
require 'liquid'

Liquid::Template.error_mode = :strict

data = {
  'companies' => [
    {
      'name' => 'Apple', 'founders' => [
        { 'name' => 'Steve Jobs' },
        { 'name' => 'Steve Wozniak' }
      ]
    },
    {
      'name' => 'Microsoft', 'founders' => [
        { 'name' => 'Bill Gates' },
        { 'name' => 'Paul Allen' }
      ]
    }
  ]
}

template = ''

Liquid::Template.parse(template).render(data)
