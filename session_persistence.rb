class SessionPersistence
  def initialize(session)
    @session = session
    @session[:lists] ||= []
  end

  def find_list(id)
    @session[:lists].find {|list| list[:id] == id}
  end

  def find_todo(list_id, todo_id)
    todos = find_list(list_id)[:todos]
    todos.find {|todo| todo[:id] == todo_id}
  end

  def all_lists
    @session[:lists]
  end

  def create_new_list(list_name)
    list_id = next_element_id(@session[:lists])
    @session[:lists] << {id: list_id, name: list_name, todos: []}
  end

  def update_list_name(id, new_name)
    list = find_list(id)
    list[:name] = new_name
  end

  def delete_list(id)
    @session[:lists].reject! { |list| list[:id] == id }
  end

  def create_new_todo(list_id, todo_name)
    list = find_list(list_id)
    id = next_element_id(list[:todos])
    list[:todos] << {id: id, name: todo_name, completed: false}
  end

  def delete_todo_from_list(list_id, todo_id)
    list = find_list(list_id)
    list[:todos].reject! { |todo| todo[:id] == todo_id }
  end

  def update_todo_status(list_id, todo_id, new_status)
    list = find_list(list_id)
    todo = list[:todos].find { |t| t[:id] == todo_id}
    todo[:completed] = new_status
  end

  def mark_all_todos_as_completed(list_id)
    list = find_list(list_id)
    list[:todos].each do |todo|
      todo[:completed] = true
    end
  end

  private

  # Find the greatest id number in the array of hashes, and add 1 to it.
  def next_element_id(elements)
    return 1 if elements.empty?
    max = elements.map {|element| element[:id] }.max
    max + 1
  end
end