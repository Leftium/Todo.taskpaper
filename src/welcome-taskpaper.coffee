exports.welcomeTaskpaper =
    """
    Welcome:
        - Todo.taskpaper knows about projects, tasks, notes, and tags.
        - Various enhanced views assist analysis and editing.
        - Delete this text when you are ready to start your own lists.

    Special Features of Todo.taskpaper:
        - The CodeMirror view and interactive console are linked together.
            1. In the REPL try: outline.root.firstChild.setAttribute('data-done', '')
            2. In CodeMirror: change "Welcome" to "Introduction"
            3. In the REPL try: console.log outline.serialize()
        - The browser DevTools are also connected!
            1. In the REPL try: alert document.location
            2. Open the developer console (CTRL-SHIFT-J in Chrome)
            3. In the console try: outline.serialize()
        - Use the birch variable just like the docs:
            https://github.com/jessegrosjean/birch-outline/blob/master/doc/getting-started.md#node


    To Create Items:
        - To create a task, type a dash followed by a space.
        - To create a project, type a line ending with a colon.
        - To create a tag, type '@' followed by the tag’s name.
    To Organize Items:
        - To indent items press the Tab key.
        - To un-indent items press Shift-Tab.
        - To mark a task done add a "@done" tag.
    To Fold, Focus, and Filter Items:
        - To fold/unfold an item click the arrow to the left of the item.
        - To focus on a single project...  @available(soon)
        - To filter your list...  @available(soon)
    """
