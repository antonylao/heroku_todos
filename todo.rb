require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

helpers do
  def list_complete?(list)
    todos_count(list) > 0 && todos_remaining_count(list) == 0
  end

  def list_class(list)
    "complete" if list_complete?(list)
  end

  def todos_count(list)
    list[:todos].size
  end

  def todos_remaining_count(list)
    list[:todos].select { |todo| !todo[:completed] }.size
  end

  def sort_lists(lists, &block)
    complete_lists, incomplete_lists = lists.partition {|list| list_complete?(list)}

    incomplete_lists.each(&block)
    complete_lists.each(&block)
  end

  def sort_todos(todos, &block)
    complete_todos, incomplete_todos = todos.partition {|todo| todo[:completed]}

    incomplete_todos.each(&block)
    complete_todos.each(&block)
  end
end

# Return an error message if the name is invalid. Return nil if the name is valid.
def error_for_list_name(name)
  if !((1..100).cover?(name.size))
    "List name must be between 1 and 100 characters."
  elsif session[:lists].any? { |list| list[:name] == name}
    "List name must be unique."
  end
end

# Return an error message if the name is invalid. Return nil if the name is valid.
def error_for_todo_name(name)
  if !((1..100).cover?(name.size))
    "Todo name must be between 1 and 100 characters."
  end
end

# Return the list at the specified index if it exists. Otherwise redirects to "/lists" (any subsequent code is not executed)
def load_list(id)
  list = session[:lists].find {|list| list[:id] == id}
  return list if list

  session[:error] = "The specified list was not found."
  redirect "/lists"
end

# Find the greatest todo id number, and add 1 to it. If the todo with the greatest id is deleted, a new todo will reuse this id.
def next_todo_id(todos)
  return 1 if todos.empty?
  max = todos.map { |todo| todo[:id] }.max
  max + 1
end

# Same logic as `next_todo_id` method
def next_list_id(lists)
  return 1 if lists.empty?
  max = lists.map {|list| list[:id] }.max
  max + 1
end

before do
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

# View list of lists
get "/lists" do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

# Render the new list form
get "/lists/new" do
  erb :new_list, layout: :layout
end

# Create a new list
post "/lists" do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  lists = session[:lists]

  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    list_id = next_list_id(lists)
    lists << {id: list_id, name: list_name, todos: []}
    session[:success] = "The list has been created."
    redirect "/lists"
  end
end

# View a single todo list
get "/lists/:id" do
  @list_id = params[:id].to_i
  @list = load_list(@list_id)
  erb :list, layout: :layout
end

# Edit an existing todo list
get "/lists/:id/edit" do
  id = params[:id].to_i
  @list = load_list(id)
  erb :edit_list, layout: :layout
end

# Update an existing todo list
# (if the user use the same name, it will be considered an error)
post "/lists/:id" do
  id = params[:id].to_i
  @list = load_list(id)

  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)

  if error
    session[:error] = error
    erb :edit_list, layout: :layout # needs to have @list to render properly
  else
    @list[:name] = list_name
    session[:success] = "The list name has been updated."
    redirect "/lists/#{id}"
  end
end

# Delete a todo list
post "/lists/:id/delete" do
  id = params[:id].to_i
  list = load_list(id)

  session[:lists].reject! { |list| list[:id] == id }

  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    # session[:success] = "The list #{list[:name]} has been deleted." # 500 response when applied
    "/lists"
  else
    session[:success] = "The list #{list[:name]} has been deleted."
    redirect "/lists"
  end
end

# Add a new todo to a list
post '/lists/:list_id/todos' do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)

  todo_name = params[:todo].strip
  error = error_for_todo_name(todo_name)

  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    id = next_todo_id(@list[:todos])
    @list[:todos] << {id: id, name: todo_name, completed: false}
    session[:success] = "The todo '#{todo_name}' was added."
    redirect "/lists/#{@list_id}"
  end
end

# Delete a todo from a list
post "/lists/:list_id/todos/:todo_id/delete" do
  list_id = params[:list_id].to_i
  list = load_list(list_id)
  todo_id = params[:todo_id].to_i

  deleted_todo = list[:todos].find { |todo| todo[:id] == todo_id }
  list[:todos].reject! { |todo| todo[:id] == todo_id }

  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    status 204 # tells the browser that there is no content
  else
    deleted_todo_name = deleted_todo[:name]
    session[:success] = "The todo '#{deleted_todo_name}' was deleted."
    redirect "/lists/#{list_id}"
  end
end

# Update the status of a todo
post "/lists/:list_id/todos/:todo_id" do
  list_id = params[:list_id].to_i
  list = load_list(list_id)

  todo_id = params[:todo_id].to_i
  todo = list[:todos].find { |todo| todo[:id] == todo_id}

  is_completed = (params[:completed] == "true")
  todo[:completed] = is_completed
  session[:success] = "The todo '#{todo[:name]}' was updated."
  redirect "/lists/#{list_id}"
end

# Mark all todos as complete for a list
post "/lists/:id/complete_all" do
  list_id = params[:id].to_i
  list = load_list(list_id)
  list[:todos].each do |todo|
    todo[:completed] = true
  end

  session[:success] = "All todos have been completed."
  redirect "/lists/#{list_id}"
end
