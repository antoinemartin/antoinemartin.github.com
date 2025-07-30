---
title: Useful Python packages discovery sites
date: 2022-05-02
slug: 2022/05/02/useful-python-packages-discovery-sites
Categories: ['Python', 'Reference']
tags: [python, pypi, trends, libraries]
draft: false
toc:
    enable: true
---

Python is an awesome language with an awesome ecosystem. It is both mature and
very active. You are rarely left alone when you need to be doing something new.
There are always one or more open source libraries or framework to help you
achieve your goal.

But now you're left with a dilemma: Which one to choose ?

<!-- more -->

The criteria are fairly simple. You want a library actively used and maintained,
with the biggest community possible. But you want also a library still having
momentum. You don't want to invest too much is a technology on the _downward
slope_. Without offense, people still doing Struts or ActionScript know what I
mean.

I have often been surprised by people selecting technologies only because it was
the first they came around. In python, possibly because of
[PEP20](https://peps.python.org/pep-0020/), there are less options than with
other languages. But for instance, in the frontend world, I have often been
surprised of people not visiting
[npmtrends.com](https://www.npmtrends.com/@reach/router-vs-react-router-vs-router5-vs-universal-router)
before choosing a SPA page router, given the number of alternatives available.

The most used technology or the most trendy one may not suit your need and you
may have a good reasong for picking another one, but you should do that
knowingly.

The following sites are the ones I found useful while trying to compare python
libraries and frameworks technologies together. I put them here in order to
remember them. You may find them useful for you. Don't hesitate to tell me about
the ones I forgot in the comments.

## Measuring community

<https://star-history.com/> Allows comparing the github stars progression of
several projects.

<!-- markdownlint-disable -->

{{<image src="/images/blacksheep.png" caption="`blacksheep` never took off while `fastapi` gets closer to `flask`" width="60%" >}}

<!-- markdownlint-restore -->

Stackoverflow trends data (<https://insights.stackoverflow.com/trends>) when
available, shows medium to long term usage among newcomers. Only popular stuff
will show up, however.

{{<image src="/images/stackoverflow.png" caption="`flask` has peeked during pandemic" width="60%" >}}

## Looking at dependent projects

I use <https://www.wheelodex.org/> to look at the projects that depend on a
candidate, to assess its users community size and maturity. For instance, at the
time of this writing, **888** projects depend on `FastAPI` while **4,121**
depend on `Flask` and **12,357** on `click`. For less outreaching projects,
digging into the dependents may show that a lot of them have not left the
experiment (version `0.0.1`) stage.

<https://pydigger.com/> is about searching names in package metadata. As it sort
answers by descending release dates, it allows assessing recent activity around
a candidate.

## Measuring downloads

<https://pypistats.org> gives official packages PyPi donwnload stats, by Python
version, major and minor. It gives only stats for the last 6 months and the lack
of moving averages makes the graphs hard to interpret. It's only useful for
young projects.

{{<image src="/images/pypistats.png" caption="pypistats example" width="50%" >}}

<https://piptrends.com/> present the above stats but ressembles npmtrends,
allowing comparing packages together.

{{<image src="/images/piptrends.png" caption="piptrends example" width="50%" >}}

<https://packagegalaxy.com/> has smoother graphs that also make release dates
appear. A download peak just after a release may show a feature breakthrough
(see below).

{{<image src="/images/packagegalaxy.png" caption="packagegalaxy example" width="50%" >}}

## Others

<https://www.techempower.com/> benchmarks web frameworks, not only python. As
with any benchmark, results need to be taken into account with a grain of salt.

I used to visit <https://pythonwheels.com> to avoid using python packages that
were not available as wheels. But a visit to the site now makes clear that there
are not much left.

## Conclusion

The above sites and information are just to know where you stand before
investing your time and energy on a new toy. Sometimes however, you will go
against the hints that the above sites give you (I'm looking at you, poetry).
