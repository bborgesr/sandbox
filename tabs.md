NEWS item
----

This is a maintenance release of Shiny, mostly aimed at fixing bugs and introducing minor features. The most notable additions in this version of Shiny are the introduction of the reactiveVal() function (it's like reactiveValues(), but it only stores a single value), and that the choices of radioButtons() and checkboxGroupInput() can now contain HTML content instead of just plain text.

* **Dynamic tabs:** added six functions (`insertTab`, `appendTab`, `prependTab`, `removeTab`, `showTab` and `hideTab`) that allow you to dynamically insert, remove, show and hide a `tabPanel()` (and other suitable elements) in an existing `tabsetPanel()` (or equivalent UI container). ([#1794](https://github.com/rstudio/shiny/pull/1794))

--

### Dynamic tabs
Added six functions (`insertTab`, `appendTab`, `prependTab`, `removeTab`, `showTab` and `hideTab`) that allow you to dynamically insert, remove, show and hide a `tabPanel()` (and other suitable elements) in an existing `tabsetPanel()` (or equivalent UI container). ([#1794](https://github.com/rstudio/shiny/pull/1794))

These functions are completely general to all Shiny UI elements that take in `tabPanel`s sub-elements, which are:

  * `tabsetPanel`
  * `navbarPage` (including `navbarMenu` -- see more below)
  * `navlistPanel`

The first argument of all new six functions (called `inputId`) is the `id` argument that you give your `tabsetPanel` (or `navbarPage` or `navlistPanel`) when you first create it.
   
**Note to app authors**: This means that if you want to use this functionality in your app, you must give an `id` to your `tabsetPanel` (or `navbarPage` or `navlistPanel`), even though this is not required (like it is for most other Shiny inputs).
   
The remaining arguments refer to the tab you want to insert, remove, show or hide. Let's start with easier cases of showing, hiding and removing.

#### Showing, hiding and removing

Here are the signatures of the three tab functions:

```r
removeTab(inputId, target, session = getDefaultReactiveDomain())

hideTab(inputId, target, session = getDefaultReactiveDomain())

showTab(inputId, target, select = FALSE,
  session = getDefaultReactiveDomain())
```

In addition to `inputId`, the remaining arguments are the expected ones:

  * `session` is the shiny session you're in (you don't need to supply it directly).
  
  * for `showTab()`, the `select` argument specifies if the `tab` should be selected upon being shown.

  * `target` is the `value` of the `tabPanel()` to be removed, hidden or shown, respectively. For `navbarPage()`, in addition to removing/hiding/showing conventional `tabPanels()` (whether at the top level or nested inside a `navbarMenu()`), you can also apply those actions to an entire `navbarMenu()`. For the latter case, `target` should be the `menuName` that you gave your `navbarMenu()` when you first created it (by default, this is equal to the value of the `title` argument).

#### Insertion

Here are the signatures of the three tab insertion functions:

```r
insertTab(inputId, tab, target, position = c("before", "after"),
  select = FALSE, session = getDefaultReactiveDomain())

prependTab(inputId, tab, select = FALSE, menuName = NULL,
  session = getDefaultReactiveDomain())

appendTab(inputId, tab, select = FALSE, menuName = NULL,
  session = getDefaultReactiveDomain())
```

As the names suggest, these functions add a new tab inside an existing `tabsetPanel` (or equivalent). The functions `prependTab()` and `appendTab()` are helpers to allow you to do those actions without referencing any specific tab. In contrast, when you use `insertTab()`, you need to provide the `target` argument, which is the value of the tab next to which the new one should be placed (the `position` argument specifies whether it is placed before or after `target`).

The three common arguments are `tab`, `select` and `session`. In reverse order:

  * `session` is the shiny session you're in (you don't need to supply it directly).
  
  * `select` specifies if the `tab` should be selected upon being inserted.
  
  * `tab` is the sub-element that you want to insert. Usually, this will be a `tabPanel`: 
  
  ```r
  appendTab(inputId = "tabs", 
                  tab = tabPanel("Test", "test page))
  ```
   
  However, _if you are inserting into a `navbarPage` container_, in addition to `tabPanel`s, you can also insert: 

   * a whole, new `navbarMenu`: 
     
       ```r
       appendTab(inputId = "tabs", 
                      tab = navbarMenu("More",
    						  tabPanel("Table", "Table page"),
    						  tabPanel("About", "About page"),
    						  "------",
    						  "Even more!",
    						  tabPanel("Email", "Email page")))
       ```

   
   * a tab that is placed inside an existing `navbarMenu`. There are actually three ways of doing this, one for each insertion function:

     1) If you want to append a tab to the end of a `navbarMenu` with `menuName` "More", it looks just like appending a tab to the end of a `tabsetPanel` or `navbarPage` or `navlistPanel`, except that you also need to specify one extra argument: `menuName = "More"`. I.e. the `menuName` argument to `append` must be the same as the `menuName` argument that you gave your navbarMenu when you first created it (by default, this is equal to the value of the `title` argument). Note that you still need to set the `inputId` argument to whatever the `id` of the parent navbarPage is. If `menuName` is left as `NULL`, the tab will be prepended (or appended) to whatever `inputId` is:
     
     ```r
     # appends tab to an existing navbarPage with id = "tabs"
	  appendTab(inputId = "tabs", 
	                  tab = tabPanel("Test", "test page))
	                  
	  # appends tab to an existing navbarPage with id = "tabs"
	  appendTab(inputId = "tabs", 
	                  tab = tabPanel("Test", "test page),
	                  menuName = "More")
	  ```

   
   * plain text that is placed inside an existing `navbarMenu` (this is because the `navbarMenu` function also accepts strings, which will be used as menu section headers. If the string is a set of dashes like "----" a horizontal separator will be displayed in the menu).
    
    
--

An app for dynamic testing and exploring (includes all possibilities): https://beta.rstudioconnect.com/content/2917/
Here are the three UI tabset-like containers that these functions apply to (i.e. an instance of one of these things must be provided to the desired function through the inputId arg):


There is also the case of navbarMenu, which is a dropdown menu that a navbarPage can have (instead of the standard tabPanelitems, though those are fine as well). A navbarMenu can be inserted/removed/hidden/shown, just like a tabPanel (for the targetargument, supply the menuName of the navbarMenu, instead of the value of the tabPanel). You can also add more tabPanels or text (dividers and header) inside a navbarMenu.

For example, consider we have a navbarPage (with id "navbarPage") that has a navbarMenu (with menuName "menu"), which itself includes another two tabs ("Foo" and "Bar"). Then, using insertTab(inputId = "navbarPage", target = "Foo", tab = ...) will insert the tab before "Foo" (notice how you don't need to supply the name of the navbarMenu, since target = "Foo" already gives us the necessary info).

If you instead want to prepend/append a tab to the beginning/end of a navbarMenu, you do need to supply the menuName:

prependTab(inputId = "navbarPage", menuName = "menu", tab = ...)
appendTab(inputId = "navbarPage", menuName = "menu", tab = ...)

--

We need these test cases for anywhere we insert dynamic UI:

1. `<script>` blocks should run

2. `<script>` blocks should only run once

3. `head()`/`singleton()` should be respected

4. HTML widgets should work

    a. Even when the dependencies are not part of the initial page load

5. Shiny inputs/outputs should work

6. Subapps should work (include a `shinyApp` object right in the UI)


I'm pretty sure at least number 1 is failing for `insertUI` where the position is not the default "replace"? Yes, see [this issue]()


### Test cases:

- appendTab to navbarPage
- appendTab to navbarPage