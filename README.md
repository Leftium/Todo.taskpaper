## Todo.taskpaper

Enhanced text editor for [TaskPaper](http://www.taskpaper.com/) files that runs in your browser.


### Try a live demo in your browser: [leftium.github.io/Todo.taskpaper](https://leftium.github.io/Todo.taskpaper/)

Different URLS result in different behavior:

- [leftium.github.io/Todo.taskpaper/#/public/Top+Secret.txt](https://leftium.github.io/Todo.taskpaper/#/public/Top+Secret.txt) Opens text files from *your* Dropbox. 
- [leftium.github.io/Todo.taskpaper/#BLANK](https://leftium.github.io/Todo.taskpaper/#BLANK) Opens a blank outline.
- [leftium.github.io/Todo.taskpaper/#DEMO&cs=%3E%20s...alert%20s%3B%20s](https://leftium.github.io/Todo.taskpaper/#DEMO&cs=%3E%20s%20%3D%20%22I%27m%20CoffeeScript%20from%20the%20Todo.taskpaper%20URL%20hash!%22%0A%3E%20alert%20s%3B%20s) Run/share CoffeeScript [encoded](http://meyerweb.com/eric/tools/dencoder/) in the URL.
- [leftium.github.io/Todo.taskpaper](https://leftium.github.io/Todo.taskpaper) By default, opens an introductory welcome.taskpaper file.




![Screenshot](http://leftium.github.io/Todo.taskpaper/Todo.taskpaper.screenshot.png)


### The Todo.taskpaper Vision, and What's Coming:

- When completed, Todo.taskpaper will support many different enhanced views. Multiple types of views on the same document allows adding features without cluttering the interface. Incompatible features that could otherwise not work together can each have their own views. Some example views I'm thinking of:
	- Calendar/scheduler view (similar to [NotePlan][noteplan])
	- Priority view: tasks automatically sorted by @due/@priority
	- Agenda view: dependent tasks hidden/folded away
	- Bookmarks view: optimized for organizing URL's (inspired by [Bkmks.com][bkmks])
- Individual tasks may be rendered differently based on their tags. For example, a @bookmark tag causes the task to be rendered with a favicon in place of the dash.
- The interactive console will expose an intuitive character string view that is synchronized to the outline. Modify the string and the outline object is automatically updated. Modify the outline object and the string is automatically updated.
- In addition, you will be able to create and share your own custom views via a plugin API.

### Currently Implemented Features:

- **Basic text editor.** With support for folding.
- **Interactive console with [birch-outline][birch-outline].** Accessed via embedded [CoffeeScript console][cs-repl].
- **Synchronization between birch-outline and the text editor.** Instant and automatic!
- **Load files from Dropbox.** Two-way sync coming soon...
- **Share snippets of CoffeeScript** This [issue](https://github.com/jessegrosjean/birch-outline/issues/3) for birch-outline links to a live reproduction.  

### Planned Features

- Dropbox Sync
- Recurring tasks
- Enhanced views
	- Calendar View
	- Linkify and shorten URL's automatically

---

### History and Background of Todo.taskpaper

This proof-of-concept only took a few days to develop, but I've been developing the idea for over a decade. When I started, I didn't know about TaskPaper. I had my own special format for paper to-do lists. However, paper lists got messy and I regularly found myself copying unfinished tasks to a fresh sheet of paper by hand.

Then I discovered [todo.txt](http://www.todotxt.com/). Using the CLI to manage a plain-text file was pretty clever. I tried to make it more clever: I figured the browser was an even more ubiquitous platform than the CLI, and allowed advanced GUI interaction.

I ported Todo.txt-CLI to the browser: [Todo.html](https://github.com/Leftium/todo.html). The original vision was a single text file that was both a text file and HTML web app *at the same time*. Start editing it in a regular text editor and process it with todo.txt-CL, then open in a browser the next moment to get a great visualization of your tasks! (I had stuffed all the minimized HTML/CSS/JS into a single line at the bottom of a single todo.html file. This file could save itself like [TiddlyWiki](http://tiddlywiki.com/).)

Alas, this idea was *too* clever. I got an initial version working, but I hit the limits of the todo.txt format. Text editors did not like single lines of that were over 500KB long! So around this time I switched to the TaskPaper format. By folding the HTML/CSS/JS code under a project, I was able to split it into shorter lines that editors didn't choke on. The TaskPaper format also had other advantages:

- it was more flexible and I could add notes related to tasks
- the concept of tags with attributes was really useful
- the natural hierarchy lent itself well to dependent tasks and sub-tasks

I finally had to give up the idea of a dual plain-text/html-web-app file that saves itself. Storing the code with the data in a single file does not work as well as I had hoped on mobile (bandwith/browser issues). But I still had hopes for an advanced editor/visualization of taskpaper tasks via the browser!

Then I ran into another challenge: the TaskPaper format was more complex and thus more difficult to parse. I toyed with the idea of writing my own custom lexer/parser, but I'm more interested in UX than compiler design. So I shelved this project until I found [birch-outline](https://github.com/jessegrosjean/birch-outline).




[birch-outline]: http://github.com/jessegrosjean/birch-outline
[cs-repl]: http://larryng.github.io/coffeescript-repl
[noteplan]: http://noteplan.co
[bkmks]: http://Bkmks.com