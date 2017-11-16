---
layout: post
title: Dynamic tabs
author: Bárbara Borges Ribeiro
---

In the release of Shiny 1.0.4, we added six functions (`insertTab`, `appendTab`, `prependTab`, `removeTab`, `showTab` and `hideTab`) that allow you to dynamically insert, remove, show and hide a `tabPanel()` (and other suitable elements) in an existing `tabsetPanel()` (or equivalent UI container).

These functions are completely general to all Shiny UI elements that take in `tabPanel` sub-elements, which are:

<ul>
  <li markdown="1" style="padding-bottom: 5px;">`tabsetPanel`;

  <li markdown="1" style="padding-bottom: 5px;">`navbarPage` (including `navbarMenu` -- see more below);

  <li markdown="1" style="padding-bottom: 5px;">`navlistPanel`.
{::nomarkdown}</ul>{:/nomarkdown}

The first argument of all new six functions (called `inputId`) is the `id` argument that you give your `tabsetPanel` (or `navbarPage` or `navlistPanel`) when you first create it.

**Note to app authors**: This means that if you want to use this functionality in your app, you must give an `id` to your `tabsetPanel` (or `navbarPage` or `navlistPanel`), even though this is not required (like it is for most other Shiny inputs).

This article explains the remaining arguments and explores the new functions with a few examples. Let's start with easier cases of showing, hiding and removing.

## Showing, hiding and removing

Here are the signatures of the three tab functions:

{% highlight r %}
removeTab(inputId, target, session = getDefaultReactiveDomain())

hideTab(inputId, target, session = getDefaultReactiveDomain())

showTab(inputId, target, select = FALSE, session = getDefaultReactiveDomain())
{% endhighlight %}

In addition to `inputId`, the remaining arguments are as follows:

<ul>
  <li markdown="1" style="padding-bottom: 10px;">`session` is the shiny session you're in (you don't need to supply it directly).

  <li markdown="1" style="padding-bottom: 10px;">for `showTab()`, the `select` argument specifies if the `tab` should be selected upon being shown.

  <li markdown="1" style="padding-bottom: 10px;">`target` is the `value` of the `tabPanel()` to be removed, hidden or shown, respectively. For `navbarPage()`, in addition to removing/hiding/showing conventional `tabPanel()`s (whether at the top level or nested inside a `navbarMenu()`), you can also apply those actions to an entire `navbarMenu()`. For the latter case, `target` should be the `menuName` that you gave your `navbarMenu()` when you first created it (by default, this is equal to the value of the `title` argument).
{::nomarkdown}</ul>{:/nomarkdown}

## Insertion

Here are the signatures of the three tab insertion functions:

{% highlight r %}
insertTab(inputId, tab, target, position = c("before", "after"),
  select = FALSE, session = getDefaultReactiveDomain())

prependTab(inputId, tab, select = FALSE, menuName = NULL,
  session = getDefaultReactiveDomain())

appendTab(inputId, tab, select = FALSE, menuName = NULL,
  session = getDefaultReactiveDomain())
{% endhighlight %}

As the names suggest, these functions add a new tab inside an existing `tabsetPanel` (or equivalent). The functions `prependTab()` and `appendTab()` are helpers to allow you to do those actions without referencing any specific tab. In contrast, when you use `insertTab()`, you need to provide the `target` argument, which is the value of the tab next to which the new one should be placed (the `position` argument specifies whether it is placed before or after `target`).

The three common arguments are `tab`, `select` and `session`. In reverse order:

<ul>
  <li markdown="1" style="padding-bottom: 10px;">`session` is the shiny session you're in (you don't need to supply it directly).

  <li markdown="1" style="padding-bottom: 10px;">`select` specifies if the `tab` should be selected upon being inserted.

  <li markdown="1" style="padding-bottom: 10px;">`tab` is the sub-element that you want to insert. Usually, this will be a `tabPanel`:

{% highlight r %}
appendTab(inputId = "tabs", tab = tabPanel("Test", "test page"))
{% endhighlight %}

{::nomarkdown}</ul>{:/nomarkdown}

### `navbarPage` and `navbarMenu`

So far, we've only considered the insertion of `tabPanel`s, which However, _if you are inserting into a `navbarPage` container_, in addition to `tabPanel`s, you can also insert:

<ul>
  <li markdown="1" style="padding-bottom: 10px;">a whole, new `navbarMenu`:

{% highlight r %}
appendTab(inputId = "tabs",
 tab = navbarMenu("More",
   tabPanel("Table", "Table page"),
   tabPanel("About", "About page"),
   "------",
   "Even more!",
   tabPanel("Email", "Email page")
 )
)
{% endhighlight %}


  <li markdown="1" style="padding-bottom: 10px;">a tab that is placed inside an existing `navbarMenu`. There are actually three ways of doing this, one for each insertion function:

   <ol>
     <li markdown="1" style="padding-bottom: 10px;">If you want to append a tab to the end of a `navbarMenu` with `menuName` "More", it looks just like appending a tab to the end of a `tabsetPanel` or `navbarPage` or `navlistPanel`, except that you also need to specify one extra argument: `menuName = "More"`. I.e. the `menuName` argument to `append` must be the same as the `menuName` argument that you gave your navbarMenu when you first created it (by default, this is equal to the value of the `title` argument). Note that you still need to set the `inputId` argument to whatever the `id` of the parent navbarPage is. If `menuName` is left as `NULL`, the tab will be prepended (or appended) to whatever `inputId` is:

{% highlight r %}
# appends tab to an existing navbarPage with id = "tabs"
appendTab(inputId = "tabs", tab = tabPanel("Test", "test page"))

# appends tab to an existing navbarPage with id = "tabs"
appendTab(inputId = "tabs", tab = tabPanel("Test", "test page"),
  menuName = "More")
{% endhighlight %}
{::nomarkdown}</ol>{:/nomarkdown}

  <li markdown="1" style="padding-bottom: 10px;">plain text that is placed inside an existing `navbarMenu` (this is because the `navbarMenu` function also accepts strings, which will be used as menu section headers. If the string is a set of dashes like "----" a horizontal separator will be displayed in the menu).

{::nomarkdown}</ul>{:/nomarkdown}


--


There is also the case of navbarMenu, which is a dropdown menu that a navbarPage can have (instead of the standard tabPanelitems, though those are fine as well). A navbarMenu can be inserted/removed/hidden/shown, just like a tabPanel (for the targetargument, supply the menuName of the navbarMenu, instead of the value of the tabPanel). You can also add more tabPanels or text (dividers and header) inside a navbarMenu.

For example, consider we have a navbarPage (with id "navbarPage") that has a navbarMenu (with menuName "menu"), which itself includes another two tabs ("Foo" and "Bar"). Then, using insertTab(inputId = "navbarPage", target = "Foo", tab = ...) will insert the tab before "Foo" (notice how you don't need to supply the name of the navbarMenu, since target = "Foo" already gives us the necessary info).

If you instead want to prepend/append a tab to the beginning/end of a navbarMenu, you do need to supply the menuName:

prependTab(inputId = "navbarPage", menuName = "menu", tab = ...)
appendTab(inputId = "navbarPage", menuName = "menu", tab = ...)