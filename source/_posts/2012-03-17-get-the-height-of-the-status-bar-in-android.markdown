---
layout: post
title: "Get the height of the status bar in Android"
date: 2012-03-17 09:09
comments: true
categories: 
---

Sometimes in Android, the flexible layout system is not flexible enough and you
need to make some computations inside your code. In these computations, you may
need to subtract the size of the status bar. Stackoverflow gives you 
[some answers](http://stackoverflow.com/questions/3407256/height-of-status-bar-in-android),
but they all rely on the fact that te status bar is shown at the time you make 
your computation. If you are in full screen mode, by having called for instance:

``` java
getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN)
```

It doesn't work.

<!-- more -->

The height of the status bar is contained in a dimension resource called
`status_bar_height`. It's not part of the public resources, so you can't access 
it directly from your code with `android.R.dimen.status_bar_height`. You can
however compute it at runtime with the following code:

``` java
	public int getStatusBarHeight() {
		int result = 0;
		int resourceId = getResources().getIdentifier("status_bar_height", "dimen", "android");
		if (resourceId > 0) {
			result = getResources().getDimensionPixelSize(resourceId);
		}
		return result;
	}
```

You need to put this method in a `ContextWrapper` class.

Hope it helps.
