---
layout: post
title: Interacting with databases (Intro to pool)
edited: 2017-09-25
author: Bárbara Borges Ribeiro
description: Connecting to an external database from Shiny is often necessary. However, it is important to follow best practices in order to protect your app from leaky connections, SQL injections or simply a lack of responsiveness.
---

Connecting to an external database from Shiny is often necessary. However, it is important to follow best practices in order to protect your app from leaky connections, SQL injections or simply a lack of responsiveness. If you are new to databases in R, you should visit <https://db.rstudio.com/>, RStudio's own compilation of best practices and helpful packages when it comes to working with databases in R. In order to be well equipped to deal with databases from Shiny, you need to know at least a minimum from that website:

* [using `dplyr` for databases](https://db.rstudio.com/dplyr): use regular `dplyr` syntax to query relational databases (no _SQL_ knowledge required!);
* [the `DBI` package](https://db.rstudio.com/dbi): this is a much older package than `dplyr`, and it is important to know about if you need a lower level package that gives you the entire power of _SQL_ (for any DBI-compliant backend);
* [running queries safely](https://db.rstudio.com/best-practices/run-queries-safely): avoid the dread of SQL injections in your code.

Finally, if security is a concern for you, you must also check out [_Securing Deployed Content_](https://db.rstudio.com/best-practices/deployment) and [_Securing Credentials_](https://db.rstudio.com/best-practices/managing-credentials), as this article will not go over that topic at all (since it is not Shiny-specific).

## The `pool` package
So, without further ado, how do you interact with databases from Shiny? At first glance, you might not think it's any different from what you saw in the pointers above that explain how to interact with databases in R in general. While there is truth to that, a Shiny app, being interactive and possibly serving multiple users, necessitates that you think about connection management and performance.

Luckily, as always, there's a package for that! The [`pool` package](https://github.com/rstudio/pool) has quietly been around for a year and it is now finally on CRAN. This package was created exactly with the intention of making Shiny app authors' lives easier, and since it integrates seamlessly with both `DBI` and `dplyr`, we recommend you always use `pool` when connecting to a database from a Shiny app. Even if you only expect one user at a time, not having to worry about connection management is a good deal. Take a look at the [README for `pool`](https://github.com/rstudio/pool/blob/master/README.md) to learn more about connection management and the particular problem that `pool` solves.


### Concept

The `pool` package adds a new level of abstraction when connecting to a database: instead of directly fetching a connection from the database, you will create an object (called a pool) with a reference to that database. The pool holds a number of connections to the database. Some of these may be currently in-use and some of these may be idle, waiting for a query to request them. Each time you make a query, you are querying the pool, rather than the database. Under the hood, the pool will either give you an idle connection that it previously fetched from the database or, if it has no free connections, fetch one and give it to you. You never have to create or close connections directly: the pool knows when it should grow, shrink or keep steady. You only need to close the pool when you’re done.

### Sample code

The code below illustrates how to use a pool within a Shiny app (feel free to try it yourself). This is the most common pattern that you'll usually want to implement when you need to query a database from within a Shiny app -- you define the pool globally (so that it is accessible by all session) and you close the pool using Shiny's `onStop()` callback function.

{% highlight r %}
library(shiny)
library(dplyr)
library(pool)

pool <- dbPool(
  drv = RMySQL::MySQL(),
  dbname = "shinydemo",
  host = "shiny-demo.csa7qlmguqrf.us-east-1.rds.amazonaws.com",
  username = "guest",
  password = "guest"
)
onStop(function() {
  poolClose(pool)
})

ui <- fluidPage(
  textInput("ID", "Enter your ID:", "5"),
  tableOutput("tbl"),
  numericInput("nrows", "How many cities to show?", 10),
  plotOutput("popPlot")
)

server <- function(input, output, session) {
  output$tbl <- renderTable({
    pool %>% tbl("City") %>% filter(ID == input$ID) %>% collect()
  })
  output$popPlot <- renderPlot({
    df <- pool %>% tbl("City") %>% head(input$nrows) %>% collect()
    pop <- df$Population
    names(pop) <- df$Name
    barplot(pop)
  })
}

shinyApp(ui, server)
{% endhighlight %}

**Note**: using `poolClose(pool)` when you're done is very important. Because your app may have several sessions open at the same time, you want to be sure that you only close the pool when all session have disconnected (`onStop()` runs the callback function provided right after this happens). You might think that when all sessions have disconnected, it would be inconsequential what happens to the global state (where your pool lives). However, this is one of the times when you should be careful about cleanup, since not closing the pool will lead to a leaked pool (and leave existing connections in a weird state). If you don't do this, you may experience slowdowns. _TLDR_: `onStop(function() { poolClose(pool)})` -- don't forget about it!



Now that you know how to use DBI, it's time to talk about some possible problems -- in particular, connection management and performance. To make it as easy as possible for you not to run into problems (or even having to worry about their existence), there is a brand new package, `pool`, that takes care of this. This adds a new level of abstraction when connecting to a database: instead of directly fetching a connection from the database, you will create an object (called a pool) with a reference to that database. The pool holds a number of connections to the database. Some of these may be currently in-use and some of these may be idle, waiting for a query to request them. Each time you make a query, you are querying the pool, rather than the database. Under the hood, the pool will either give you an idle connection that it previously fetched from the database or, if it has no free connections, fetch one and give it to you. You never have to create or close connections directly: the pool knows when it should grow, shrink or keep steady. You only need to close the pool when you're done.

**Note**: While you don't leak connections if you use a pool, if you forget to close it, you leak the pool itself. However, you will usually just have one pool open, so you'll have at most one leaked pool at any time -- which is generally not true if you're dealing directly with connections. Once you lose a reference to the pool, it will get garbage collected, destroying all associated resources. Unfortunately, there is no built-in support for closing a pool in a Shiny app (once all sessions have ended). So, for the context of using `pool` in a Shiny app, just don't worry about closing the pool. It will get garbage collected once all sessions end, so in practical terms, it displays the same behavior as if you closed it. However, if you're using `pool` in the console, you will probably want to close it once you're done with it.

The following sections illustrate how creating a connection pool helps alleviate the problems of connection manage and performance. We also show code examples that achieve the same thing with and without a pool, to hopefully demonstrate how using a pool makes your life a lot easier.

**Note**: The `pool` package is actually general enough to allow you to construct a pool of any kind of object, not just database connections. For more information on the package and its general usage, check out its [github page](https://github.com/rstudio/pool).

## Connection management and performance

When you're connecting to a database, it is important to manage your connections: when to open them, how to keep track of them, when to close them. Depending on your purpose, you might choose different connection management models. In any case, the most important thing is to not leak connections: i.e. leave a connection open once you no longer need it. Over time, leaked connections could accumulate and substantially slow down your app, as well as overwhelming the database itself. However, the frequency with which you open connections may legitimately vary from the extreme of just having one connection per app (potentially serving several sessions of the app) to the extreme of opening one connection for each query you make. Using `pool` offers you the happy middle ground -- it is safer, more robust and offers better overall performance, independently of your connection management model. Here's a simple example of using a pool within a Shiny app:



What we're doing here is creating a pool at the start of the app (if you're not using a single-file app, you could put this at the top of `server.R` or in `global.R`). Then, we reference that pool each time we make a query. By default, on creation, the pool fetches and keeps around one idle connection. When you make a query to the pool, it will always use that connection, unless it happens to already be busy in another query (this becomes more likely if you have several sessions going on at the same time). If that's the case, the pool will fetch a second connection for the current query; once that's finished, the pool with hold on to it for a minute (by default). If that second connection is requested again in that period of time, the countdown resets. Otherwise, the pool disconnects it. (See the [next article](/articles/pool-advanced.html) for information about how to customize these features.) So basically, the pool "knows" when it should have more connections and how to manage them (including disconnecting them when necessary).

To understand exactly why this logic is advantageous and how it compares to `pool`-less code, let's consider the same app using the two extreme connection management models mentioned before (i.e. only one connection per app vs. one connection per query).

### Only one connection per app

Let's consider the case of opening only one connection (without using the `pool` package). You could do this at the top of your `server.R` file (before the actual server function) or in `global.R`. Then, each query made in any session of the app refers to this one connection:

<!---
<div markdown="0">
<a data-toggle="collapse" data-target="#connection_management_example">Toggle code example</a>
</div>

<div id="connection_management_example" class="collapse">
--->
{% highlight r %}
library(shiny)
library(DBI)

conn <- DBI::dbConnect(
  drv = RMySQL::MySQL(),
  dbname = "shinydemo",
  host = "shiny-demo.csa7qlmguqrf.us-east-1.rds.amazonaws.com",
  username = "guest",
  password = "guest"
)

ui <- fluidPage(
  textInput("ID", "Enter your ID:", "5"),
  tableOutput("tbl"),
  numericInput("nrows", "How many cities to show?", 10),
  plotOutput("popPlot")
)

server <- function(input, output, session) {
  output$tbl <- renderTable({
    sql <- "SELECT * FROM City WHERE ID = ?id;"
    query <- sqlInterpolate(conn, sql, id = input$ID)
    dbGetQuery(conn, query)
  })
  output$popPlot <- renderPlot({
    query <- paste0("SELECT * FROM City LIMIT ",
                    as.integer(input$nrows)[1], ";")
    df <- dbGetQuery(conn, query)
    pop <- df$Population
    names(pop) <- df$Name
    barplot(pop)
  })
}

shinyApp(ui, server)
{% endhighlight %}
<!---
</div>

<br>
--->

The advantages to this approach are that it is fast (because, in the whole app, you only fetch one connection) and your code is kept as simple as possible. The drawbacks include:

- since there is only one connection, it cannot handle simultaneous requests (this is especially an issue if you have a complicated app or if you have more than one session open at any time);
- if the connection breaks at some point (maybe the database server crashed), you won't get a new connection (you have to exit the app and re-run it);
- even if you're not making any queries at the moment (or if you leave your app running while your gone), you're gonna have an idle connection sitting around for no reason;
- finally, if you are not quite at this extreme, and you use use more than one connection per app (but fewer than one connection per query), it can be difficult to keep track of all your connections, since you'll be opening and closing them in potentially very different places.

### One connection per query

Let's now turn our attention to the other extreme: opening (and closing) a connection for each query we make:

<!---
<div markdown="0">
<a data-toggle="collapse" data-target="#performance_example">Toggle code example</a>
</div>

<div id="performance_example" class="collapse">
--->
{% highlight r %}
library(shiny)
library(DBI)

args <- list(
  drv = RMySQL::MySQL(),
  dbname = "shinydemo",
  host = "shiny-demo.csa7qlmguqrf.us-east-1.rds.amazonaws.com",
  username = "guest",
  password = "guest"
)

ui <- fluidPage(
  textInput("ID", "Enter your ID:", "5"),
  tableOutput("tbl"),
  numericInput("nrows", "How many cities to show?", 10),
  plotOutput("popPlot")
)

server <- function(input, output, session) {
  output$tbl <- renderTable({
    conn <- do.call(DBI::dbConnect, args)
    on.exit(DBI::dbDisconnect(conn))

    sql <- "SELECT * FROM City WHERE ID = ?id;"
    query <- sqlInterpolate(conn, sql, id = input$ID)
    dbGetQuery(conn, query)
  })
  output$popPlot <- renderPlot({
    conn <- do.call(DBI::dbConnect, args)
    on.exit(DBI::dbDisconnect(conn))

    query <- paste0("SELECT * FROM City LIMIT ",
                    as.integer(input$nrows)[1], ";")
    df <- dbGetQuery(conn, query)
    pop <- df$Population
    names(pop) <- df$Name
    barplot(pop)
  })
}

shinyApp(ui, server)
{% endhighlight %}
<!---
</div>

<br>
--->

The advantages to this approach are the reverse of the disadvantages of the first approach:

- it can handle simultaneous requests, because these are always processed by different connections (it will easily handle complicated apps or multiple sessions);
- if a connection breaks, that's no big deal for your app: it will just fetch a new one (no need to restart the app);
- each connection is only open for the duration of the query it's making, so there's no idle connections sitting around (good performance for the scenario in which the app is seldom interacted with, or left idle for long);
- in addition, it is very easy to keep track of connections (as you can see, each `dbConnect` is always paired with a `dbDisconnect`), so there's virtually no danger of accidentally leaking them.

Similarly, it does less well on the things that the former approach excelled at:

- it is slow: each time we change an input, we have a fetch a connection to recalculate the reactive;
- you need a lot more (boilerplate) code to connect and disconnect the connection within each reactive.

### The best of both worlds: using a pool

Wouldn't it be nice if you could combine the advantages of the two approaches? The goal of using a pool is to minimize all the disadvantages listed above as much as possible: the pool abstracts away the logic of connection management, so that, for the vast majority of cases, you never have to deal with connections directly. Since the pool "knows" when it should have more connections and how to manage them, you have all the advantages of the second approach (one connection per query), without the disadvantages. You are still using one connection per query, but that connection is always fetched and returned to the pool, rather than getting it from the database directly. This is a whole lot faster and more efficient. Finally, the code is kept just as simple as the code in the first approach (only one connection for the entire app). In fact, if you look back at the `pool` Shiny app example, you will notice that the code structure is essentially the same as the one in the first approach.

Spend some time experimenting with `pool`. Once you feel that you have the basic idea down, read on to the [next article](/articles/pool-advanced.html) to learn how to customize your pool and to deal with transactions.

<!--
## Benchmarking

To have a clearer idea of how these three approaches relate to one another in terms of time taken to run, check the following documents. They have the exact same script, but one was [run my local machine](https://beta.rstudioconnect.com/barbara/database-benchmarking-local/) and the other was run on [RStudio's remote server](https://beta.rstudioconnect.com/barbara/database-benchmarking/report.html). As you can see, using a pool is a good compromise in terms of time. Do keep in mind, however, that even though the the "one connection per app" model is the fastest, it has many disadvantages: namely, it will completely break down if you are running more than one session of your app (i.e. two or more users). Even if you're just running a single session, if that connection is requested by two queries at the same time, or if it breaks down for some reason, you're equally in trouble.
-->
