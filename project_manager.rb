#!/usr/bin/env ruby

require 'optparse'
require 'yaml'
require 'pp'

PROJECT_MANAGER_DIR="/Users/fthomasmorel/Projects/ProjectManager/"
PROJECT_MANAGER="\e[32m#{"[ProjectManager]"}\e[0m"

def gather_data
  path = `pwd`.strip
  name = path.split("/").last.strip
  git = `git remote get-url --all origin 2>&1`
  git = git.strip if !git.include? "Not a git repository"
  git = nil if git.include? "Not a git repository"
  currentProject = `cat #{PROJECT_MANAGER_DIR}.currentProject 2>&1`.strip
  hasCurrentProject = !currentProject.include?("No such file or directory")
  return path, name, git, currentProject, hasCurrentProject
end



def add_project(project, path, git=nil)
  projects = fetch_projects
  if projects[project].nil? || projects[project].empty?
    projects[project] = {
      "path" => path,
      "git" => git
    }
    File.open("#{PROJECT_MANAGER_DIR}.projects.yml", 'w') {|f| f.write projects.to_yaml }
    puts "#{PROJECT_MANAGER} Created project #{project} successfully!"
  else
    puts "#{PROJECT_MANAGER} Cannot add project: #{project} already exist!"
  end
end

def set_current_project(project)
  projects = fetch_projects
  if projects[project].nil? || projects[project].empty?
    puts "#{PROJECT_MANAGER} Cannot set current project: #{project} doesn't exist!"
  else
    `echo #{project} > #{PROJECT_MANAGER_DIR}.currentProject`
    go_to_project(project)
  end
end

def remove_project(project)
  projects = fetch_projects
  if !(projects[project].nil? || projects[project].empty?)
    projects.delete(project)
    File.open("#{PROJECT_MANAGER_DIR}.projects.yml", 'w') {|f| f.write projects.to_yaml }
    puts "#{PROJECT_MANAGER} Removed project #{project} successfully!"
  else
    puts "#{PROJECT_MANAGER} Cannot remove project: #{project} not found!"
  end
end

def go_to_project(project)
  projects = fetch_projects
  if projects[project].nil? || projects[project].empty?
    puts "#{PROJECT_MANAGER} Cannot go to project: #{project} doesn't exist!"
  else
    puts projects[project]["path"]
  end
end



def list_project
  projects = fetch_projects
  if projects.empty? then
    puts "#{PROJECT_MANAGER} No project found!"
  else
    projects.keys.each do |project|
      printf "\e[32m%-20s \e[0m%s\n", project, projects[project]["path"]
    end
  end
end



def display_info(project)
  projects = fetch_projects
  if !(projects[project].nil? || projects[project].empty?)
    printf "\e[32m%-20s \e[0m%s\n", "Directory:", projects[project]["path"]
    printf "\e[32m%-20s \e[0m%s\n", "Git URL:", projects[project]["git"]
    printf "\e[32m%-20s \e[0m%s\n", "Name:", project
  else
    puts "#{PROJECT_MANAGER} Project not found!"
  end
end

def display_help(parser)
  options = parser.parse %w[--help]
  puts options
end

def fetch_projects
  `touch "#{PROJECT_MANAGER_DIR}.projects.yml"`
  projects = YAML.load_file("#{PROJECT_MANAGER_DIR}.projects.yml")
  projects = {} if !projects
  projects
end

options = {}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: f [options]"
  opts.on('-a', '--add', 'Add a new project from the current folder') { |v| options[:add] = v }
  opts.on('-r', '--remove PROJECT', 'Remove the given project') { |v| options[:remove] = v }
  opts.on('-s', '--set PROJECT', 'Set current project') { |v| options[:set] = v }
  opts.on('-g', '--go PROJECT', 'Go to the given project') { |v| options[:go] = v }
  opts.on('-l', '--list', 'List all project') { |v| options[:list] = v }
  opts.on('-i', '--info PROJECT', 'Prints info of th given project') { |v| options[:info] = v }
  opts.on('-c', '--current', 'Prints current project') { |v| options[:current] = v }
  opts.on("-h", "--help", "Prints this help") { puts opts ; exit }
end

parser.parse!

path, name, git, currentProject, hasCurrentProject = gather_data

go_to_project(currentProject) if options.empty? && hasCurrentProject
remove_project(options[:remove]) if options[:remove]
set_current_project(options[:set]) if options[:set]
display_info(currentProject) if options[:current]
display_info(options[:info]) if options[:info]
add_project(name, path, git) if options[:add]
go_to_project(options[:go]) if options[:go]
list_project if options[:list]
