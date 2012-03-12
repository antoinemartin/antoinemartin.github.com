---
layout: post
title: "Checking Google Play signatures with Django"
date: 2012-03-12 07:43
comments: true
categories: 
- Django
- Android
---

Google play, formerly known as the Android Market, provides in-app billing in several countries.
In the [Security and Design](http://developer.android.com/guide/market/billing/billing_best_practices.html) page,
Google states the following:

> If practical, you should perform signature verification on a remote server and not on a device. 
> Implementing the verification process on a server makes it difficult for attackers to break the verification process by 
> reverse engineering your .apk file. If you do offload security processing to a remote server, be sure that the device-server handshake is secure.