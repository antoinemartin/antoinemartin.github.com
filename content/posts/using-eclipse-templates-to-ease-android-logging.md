---
title: Using Eclipse Templates to Ease Android Logging
date: "2012-03-24"
slug: "2012/03/24/using-eclipse-templates-to-ease-android-logging"
Categories: ["Development", "Android"]
tags:
  - old
  - obsolete
  - android
  - eclipse
---

Adding logs to your Android source code is sometimes the only way to really
understand what happens , especially in asynchronous situations.

If you are lazy like me, you may insert _lazy logs_ like this one:

```java
  Log.v("#LOOK#", "onStart()");
```

Instead of having less lazy code like:

```java
public class SomeActivity extends Activity {
    private static final String LOG_TAG = SomeActivity.class
            .getSimpleName();
    private static final int LOG_LEVEL = Log.VERBOSE;
...

    @Override
    public void onStart() {
        if (LOG_LEVEL <= Log.VERBOSE)
            Log.v(LOG_TAG, "onStart()");


```

But Eclipse can easily help you to avoid this and then the need to clean up your
code after debbuging.

<!-- more -->

Everybody uses content assist in Eclipse. The `CTRL+Space` shortcut alleviates
us from the need to type all those long field and method names that come out of
our imagination. With the _Templates_ feature, it can even write code for us.

Templates are editable in the preferences. To see them, select
`Window > Preferences` and then in the preferences dialog,
`Java > Editor > Templates`. The window looks like this:

![img](/images/eclipse_templates.png)

If you double click on a template you can edit it:

![img](/images/eclipse_template_edit.png)

The template name is what you type in the Editor window before hitting
`CTRL+Space` and that will make Eclipse propose you the template. I won't go
into a full explanation of the syntax of the templates, but basically the
template name is replaced by the template pattern and the content between the
`${}` is replaced either by what you type or by values computed by existing
macros. DZone gives you a good
[Visual Guide to Template](http://eclipse.dzone.com/news/visual-guide-templates-eclipse)
listing most common macros.

Now we can create our templates for both adding the Log declarations at the
beginning of our class as well as templates for inserting conditionally ran
logs.

For the header, we create a template named `alh` in `Java types member` context
with the following pattern:

```java
${:import(android.util.Log)}private static final String LOG_TAG = ${enclosing_type}.class.getSimpleName();
private static final int LOG_LEVEL = Log.${level};
${cursor}

```

The different `${}` mean:

- `${:import(android.util.Log)}`: make sure `android.util.Log` is imported.
- `${enclosing_type}`: insert the name of the type (class) we're in.
- `${level}`: when inserting, put the cursor here and wait for the user to enter
  the `level` variable.
- `${cursor}`: leave the cursor here when the user hits the `ENTER` key.

With this template, inserting the log headers in a class is achievied with the
following steps:

- type `alh` and hit `STRL+Space`.
- select the template (first choice) and hit `ENTER`
- enter the desired log level (`DEBUG` for instance) for the class and hit
  `ENTER`.
- continue coding.

This is much simpler than copy-pasting the code from another class and replacing
the class name and log level.

The following template, named `alv` in the `Java statement` context is for
inserting verbose logs:

```java
if (LOG_LEVEL <= Log.VERBOSE)
    Log.v(LOG_TAG, "${enclosing_method}() ${}");
${cursor}
```

The nice thing is that it inserts the name of the current method and wait just
after for your debug message. Just typing `Enter` will leave a log like:

```java
        if (LOG_LEVEL <= Log.VERBOSE)
            Log.v(LOG_TAG, "onStart() ");
```

Wich may be just enough.

On this model, you can create `ali`, `ald`, `ale` templates for the different
debug levels, or if you want to use `String.format()` templates like :

```java
if (LOG_LEVEL <= Log.DEBUG)
    Log.d(LOG_TAG, String.format("${enclosing_method}() ${}", ${args}));
${cursor}
```

Just adapt them to your needs.

Once you have finished debugging, if you change the `LOG_LEVEL` of your class
from let's say `VERBOSE` to `INFO`, all the `alv` templates you've entered will
become _dead code_ as the `if` surrounding the log lines is always `false`. This
is because it compares static variables, and this is just what we want. When we
compile for delivery, we want the compiler to optimize out all this code from
the binary.

However, the Java compiler will generate warnings for that. As it is not
possible to surround the log with a `@SuppressWarnings()` attribute, you may
want to change the error level of dead code from `Warning` to `Ignore`. This is
done in `Window > Preferences`,
`Java > Compiler > Error/Warnings > Potential programming problems`.

When it's time for delivery, you may want to change the `LOG_LEVEL` of all
classes to a particular value. To do that, I personally use a slightly modified
version of the `alh` header template:

```java
${:import(android.util.Log,com.eurosport.player.constants.DebugConstants)}private static final String LOG_TAG = ${enclosing_type}.class.getSimpleName();
private static final int LOG_LEVEL_LOCAL = Log.${level};
private static final int LOG_LEVEL = DebugConstants.LOG_FORCE_GLOBAL * DebugConstants.LOG_LEVEL + (1 - DebugConstants.LOG_FORCE_GLOBAL) * LOG_LEVEL_LOCAL;
${cursor}

```

That works with the `DebugConstants` interface :

```java
public interface DebugConstants {
    public static final int LOG_LEVEL = Log.INFO;
    public static final int LOG_FORCE_GLOBAL = 0;
}
```

The way the modified `alh` template works is the following:

- if the value of `DebugConstants.LOG_FORCE_GLOBAL` is 0, the `LOG_LEVEL`
  variable contains the value of the `LOG_LEVEL_LOCAL` variable.
- if the value of `DebugConstants.LOG_FORCE_GLOBAL` is 1, the `LOG_LEVEL`
  variable contains the value of the `DebugConstants.LOG_LEVEL` variable.

By having inserted this template in my classes, even if at delivery time some of
the `LOG_LEVEL_LOCAL` values are still set to `Log.VERBOSE`, by setting
`LOG_FORCE_GLOBAL` to 1, all log levels will be forced to `Log.INFO` and all the
log code for deeper debugging levels will be removed by DCE (Dead Code
Elimination).

Now, there's no more excuses to have sloppy logs in your Android code !
