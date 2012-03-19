---
layout: post
title: "Using Eclipse templates to ease Android logging"
date: 2012-03-19 07:26
comments: true
categories: 
- Android
- Java
- Eclipse
---

Adding logs to your Android source code is sometimes the only way to really 
understand what happens , especially in heavily asynchronous situations.

If you are lazy like me, you may insert _lazy logs_ like this one:

``` java
  Log.i("#LOOK#", "onStart()");
```

But Eclipse can easily help you to avoid this and then the need to clean up your 
code after debbuging.

<!-- more -->

Everybody uses content assist in Eclipse. The `CTRL+Space` shortcut alleviates 
us from the need to type all those long field and method names that come out of
our imagination. With the _Templates_ feature, it can even write code for us.

Templates are editable in the preferences. To see them, select 
`Window > Preferences` and then in the preferences dialog, `Java > Editor > Templates`.
The window looks like this:

{% img /images/eclipse_templates.png 500 %} 

If you double click on a template you can edit it:

{% img /images/eclipse_template_edit.png 500 %} 

``` java 
${:import(android.util.Log,com.eurosport.player.constants.DebugConstants)}private static final String LOG_TAG = ${enclosing_type}.class.getSimpleName();
private static final int LOG_LEVEL_LOCAL = Log.${level};
private static final int LOG_LEVEL = DebugConstants.LOG_FORCE_GLOBAL * DebugConstants.LOG_LEVEL + (1 - DebugConstants.LOG_FORCE_GLOBAL) * LOG_LEVEL_LOCAL;
${cursor}

```

``` java
if (LOG_LEVEL <= Log.DEBUG)
	Log.d(LOG_TAG, "${enclosing_method}() ${}");
${cursor}
```


``` java 
if (LOG_LEVEL <= Log.DEBUG)
	Log.d(LOG_TAG, String.format("${enclosing_method}() ${}", ${args}));
${cursor}
```

