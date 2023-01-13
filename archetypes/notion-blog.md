---
title: [[.Title]]
date: [[.LastModified.Format "2006-01-02" ]]
slug: [[.LastModified.Format "2006/01/02" ]]/[[ slug .Title ]]
description: |
  [[.Description]]
Categories:[[ range $index, $cat := .Categories]]
  - [[ $cat.Name -]]
[[- end ]]
tags:[[ range $index, $tag := .Tags]]
  - [[ $tag.Name -]]
[[- end ]]
toc:
  enable: true
---

[[.Content -]]
