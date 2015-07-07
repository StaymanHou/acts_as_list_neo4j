# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-
# stub: acts_as_list_neo4j 0.0.2 ruby lib

Gem::Specification.new do |s|
  s.name = "acts_as_list_neo4j"
  s.version = "0.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Stayman Hou"]
  s.date = "2015-07-07"
  s.description = "Make your ActiveNode acts as a list. This acts_as extension provides the capabilities for sorting and reordering a number of objects in a list.\n    The instances that take part in the list should have a +position+ field of type Integer."
  s.email = "stayman.hou@gmail.com"
  s.extra_rdoc_files = [
    "LICENSE.md",
    "README.md"
  ]
  s.files = [
    "lib/acts_as_list_neo4j.rb",
    "lib/neo4j/acts_as_list.rb"
  ]
  s.homepage = "http://github.com/rails/acts_as_list"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.4.6"
  s.summary = "acts_as_list for ActiveNode"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<neo4j>, ["~> 4.0"])
      s.add_development_dependency(%q<cutter>, ["~> 0.8"])
      s.add_development_dependency(%q<shoulda>, ["~> 3.5"])
      s.add_development_dependency(%q<rspec>, ["~> 2.5"])
      s.add_development_dependency(%q<rubocop>, ["~> 0.32"])
      s.add_development_dependency(%q<byebug>, ["~> 5.0"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.6"])
      s.add_development_dependency(%q<simplecov>, ["~> 0.10"])
    else
      s.add_dependency(%q<neo4j>, ["~> 4.0"])
      s.add_dependency(%q<cutter>, ["~> 0.8"])
      s.add_dependency(%q<shoulda>, ["~> 3.5"])
      s.add_dependency(%q<rspec>, ["~> 2.5"])
      s.add_dependency(%q<rubocop>, ["~> 0.32"])
      s.add_dependency(%q<byebug>, ["~> 5.0"])
      s.add_dependency(%q<bundler>, ["~> 1.0"])
      s.add_dependency(%q<jeweler>, ["~> 1.6"])
      s.add_dependency(%q<simplecov>, ["~> 0.10"])
    end
  else
    s.add_dependency(%q<neo4j>, ["~> 4.0"])
    s.add_dependency(%q<cutter>, ["~> 0.8"])
    s.add_dependency(%q<shoulda>, ["~> 3.5"])
    s.add_dependency(%q<rspec>, ["~> 2.5"])
    s.add_dependency(%q<rubocop>, ["~> 0.32"])
    s.add_dependency(%q<byebug>, ["~> 5.0"])
    s.add_dependency(%q<bundler>, ["~> 1.0"])
    s.add_dependency(%q<jeweler>, ["~> 1.6"])
    s.add_dependency(%q<simplecov>, ["~> 0.10"])
  end
end

