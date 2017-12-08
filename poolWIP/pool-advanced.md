---
layout: post
title: Advanced uses of pool
edited: 2017-09-25
author: Bárbara Borges Ribeiro
description: This article discusses how to handle transactions within a database connection pool context and how to customize your pool (by providing extra arguments to pool::dbPool).
---

This article discusses how to handle transactions within a database connection pool context and how to customize your pool (by providing extra arguments to `pool::dbPool`). Before reading this, you should already a good idea of [how to connect to a database from R and the basics of the `pool` package](/articles/databases.html).

## Customizing your pool

First, let's get to know our Pool object:

{% highlight r %}
library(DBI)
library(pool)

pool <- dbPool(
  drv = RMySQL::MySQL(),
  dbname = "shinydemo",
  host = "shiny-demo.csa7qlmguqrf.us-east-1.rds.amazonaws.com",
  username = "guest",
  password = "guest"
)

dbGetInfo(pool)
># $class
># [1] "Pool"
>#
># $valid
># [1] TRUE
>#
># $minSize
># [1] 1
>#
># $maxSize
># [1] Inf
>#
># $idleTimeout
># [1] 60
>#
># $pooledObjectClass
># [1] "MySQLConnection"
>#
># $numberFreeObjects
># [1] 0
>#
># $numberTakenObjects
># [1] 1

{% endhighlight %}

As you can see, `dbGetInfo()` will give you information about your pool. This can be useful to learn how many connections you have open (both free/idle and in use). But for this section, let's turn our attention to other features: `minSize`, `maxSize` and `idleTimeout`. These are extra, optional parameters that you can pass in to `dbPool()`:

- `minSize`: minimum number of connections that the pool should have at all times (default is 1);
- `maxSize`: maximum number of connections that the pool may have at any time (default is `Inf`);
- `idleTimeout`: number of seconds to wait before closing a connection, if the number of connections is above `minSize` (default is 60).

These parameters are what allows the pool to "know" when it should shrink and when it should grow. When created, the pool always creates the `minSize` number of connections, and keeps them around until they're requested. If all the idle connections are taken up when another request for a connection comes up, the pool will create a new connection. At this point, the pool will be over the `minSize`. It will keep following this pattern up until the total number of connections (both free and taken) is equal to the `maxSize`; at this point, any further requests for new connections will be denied (and throw an error). In the meantime, any connection that is created when we're over the `minSize` will have a timer attached to it: from the moment it is returned back to the pool, a countdown of `idleTimeout` seconds will start. If that connection is not requested again during that period, it will be destroyed when the countdown finishes. If it *is* requested and checked out of the pool, the countdown will the reset when it is returned back to the pool.

The optimal values of these three parameters will depend on the particulars of how your using your pool, as, together, they represent a tradeoff between how adaptable your pool is and how efficient it is. For example, a large values for all three parameters would mean that your pool is highly adaptable (it can handle spikes in traffic easily), but potentially not very efficient (it might be fetching and subsequently holding on to idle connections that are really no longer needed, if they ever were). On the other hand, small values for these parameters would mean that your pool is very strict about the number of connections it has (it will very rarely allow for idle connections). This may result in an efficient pool if traffic is consistent. However, this type of pool won't be able to handle spikes in traffic easily: on one hand, it will often have to do the computationally expensive fetching of connections directly from the database, since it doesn't hold on to idle connections for long; on the other hand, once it hits the `maxSize` number of connections, it won't be able to scale up any further.

Considering where your pool falls on this spectrum, you should choose the value for these arguments accordingly. For example, if you want a stable pool that will adapt and scale up easily (and you're not too worried about efficiency), you could do something like:

{% highlight r %}
library(DBI)
library(pool)

pool <- dbPool(
  drv = RMySQL::MySQL(),
  dbname = "shinydemo",
  host = "shiny-demo.csa7qlmguqrf.us-east-1.rds.amazonaws.com",
  username = "guest",
  password = "guest",
  minSize = 10,
  maxSize = Inf,     # this could have been omitted since it's the default
  idleTimeout = 3600 # one hour
)

dbGetInfo(pool)
># $class
># [1] "Pool"
>#
># $valid
># [1] TRUE
>#
># $minSize
># [1] 10
>#
># $maxSize
># [1] Inf
>#
># $idleTimeout
># [1] 3600
>#
># $pooledObjectClass
># [1] "MySQLConnection"
>#
># $numberFreeObjects
># [1] 9
>#
># $numberTakenObjects
># [1] 1

{% endhighlight %}

## Transactions

When talking about databases, a transaction

So far, we've recommended you always use the Pool object directly when you need to query the database. Given that the pool "knows" when to grow and shrink, for the vast majority of cases, this is a good approach (especially because it means you never have to worry about connection management and leaked connections - this is all taken care of for you). However, there is one type of situation for which this does not apply: transactions. From [Wikipedia](https://en.wikipedia.org/wiki/Database_transaction):

> Transactions provide an "all-or-nothing" proposition, stating that each work-unit performed in a database must either complete in its entirety or have no effect whatsoever. Further, the system must isolate each transaction from other transactions, results must conform to existing constraints in the database, and transactions that complete successfully must get written to durable storage.

In order for these conditions to be met, you need to have access to the same connection for longer than the duration of a query. For example, imagine you're transaction consists of two consecutive queries, A and B. You want to make sure that either both of these taken effect or neither does, and that nothing else is going on in the meantime. So the following will not work:

{% highlight r %}
dbGetQuery(pool, A)
dbGetQuery(pool, B)
{% endhighlight %}

The easiest way around this is for you to check a connection from the pool directly, and then use the appropriate DBI transaction functions:

{% highlight r %}
conn <- poolCheckout(pool)

dbBegin(conn)
dbGetQuery(conn, A)
dbGetQuery(conn, B)
dbCommit(conn)   # or dbRollback(conn) if something went wrong

poolReturn(conn)
{% endhighlight %}

When you use `poolCheckout(pool)` to get an actual connection from the pool, you become responsible for returning to the pool when you're done with it (using `poolReturn(conn)`). If you don't do this, this connection will stay open (and count as a taken connection) when, in fact, you no longer need it. So this means that you lose the connection management benefit usually associated with a pool, in return for a finer level of control over transactions. However, you still retain the performance benefits, since you don't have to go get a connection all the way to the database: you simply get it from and return it to the pool.

### Note
As of this moment, [DBI's development version](https://github.com/rstats-db/DBI) has a new function called `dbWithTransaction` that lets you pass in arbitrary R code and makes sure that is treated as a transaction. The advantage is that you don't have to remember to do `dbBegin` and `dbCommit` or `dbRollback` – that is all taken care of. For instance, the example above could be written as:

{% highlight r %}
conn <- poolCheckout(pool)

dbWithTransaction(conn, {
  dbGetQuery(conn, A)
  dbGetQuery(conn, B)
})

poolReturn(conn)
{% endhighlight %}

If an error occurs inside the body of `dbWithTransaction`, the transaction will be rolled back. If everything is successful, the transaction is committed.

As soon as this new `DBI` feature hits CRAN, the `pool` package will also wrap it, so that you  wouldn't actually need to check out a connection directly. Instead, you will simply be able to do:

{% highlight r %}
dbWithTransaction(pool, {
  dbGetQuery(pool, A)
  dbGetQuery(pool, B)
})
{% endhighlight %}

Even when this becomes a reality, however, it will still be useful to consider the first approach. If you're working on a complicated or interactive transaction (for instance, the success of your transaction could depend on some user input), you won't be able to do it all at once in a block of code as the example we've had so far. In those situations, it will be necessary to directly check out a connection from the pool and then return it when you're done.

## Future work
The `pool` package is still hot off the press at this point, so there are some features that are still in development. Let us know if there is something else that would be important for your app that we haven't covered anywhere.

Right now, here are some of the the limitations of `pool` that we hope will be addressed in future releases:

<ul>
  <li markdown="1" style="padding-bottom: 10px;">**User-defined variables**: If you need to modify a connection's default variables (which should be a fairly uncommon practice), you probably should not use the `pool` package. For example, let's say your database connections are, by default, encoded in `latin1`, and you check out a connection and change the encoding to `utf8`:

  {% highlight r %}
  conn <- poolCheckout(pool)
  dbSendQuery(conn, "SET NAMES utf8;")
  # do something with conn
  poolReturn(conn)
  {% endhighlight %}

  As of right now, these user-defined variables don't get reset when you return a connection to the pool. So, you either never set variables on connections, or if you do, you can never be sure if the next connection you fetch from the pool will be brand new (default settings) or a connection whose settings were previously changed. Since the latter is really undesirable, we currently recommend that you don't use `pool` if you do need to set variables at the connection level. In order for the resetting behavior to be supported by `pool`, it would first have to be supported by `DBI` (which in turn means that it would have to be first supported by all the DBI-compliant drivers). So, there is no telling when this difficulty may be overcome.

  <li markdown="1" style="padding-bottom: 10px;">**NoSQL databases**: At the moment and for the foreseeable future, `DBI` (and, hence, `pool`) only support relational databases (like SQLite, MySQL and PostgreSQL). If you wish to integrate a NoSQL database (e.g. MongoDB) into your Shiny app, we hope that these articles will still have helped give a sense of best practices and common problems that may arise. However, the burden will be mostly on you to find out the correct driver for your database and how to do your own connection management.
{::nomarkdown}</ul>{:/nomarkdown}
