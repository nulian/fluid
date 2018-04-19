require 'liquid'
require 'json'
data = File.read(ARGV[1])
template = File.read(ARGV[0])
hash = JSON.parse(data)
# puts Liquid::Template.parse(template).render(hash)
File.write ARGV[2], Liquid::Template.parse(template).render(hash)
