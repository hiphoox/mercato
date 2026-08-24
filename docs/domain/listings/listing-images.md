---
type: domain
title: Listing Images
description: Business rules for a listing's image gallery — ordering, the cover image, and what happens when images are added or removed.
tags: [domain, listings, images, media, gallery]
timestamp: 2026-08-24T00:00:00Z
---

A listing's images are its gallery: an ordered set of photos belonging to that listing alone. Each image records the key its file is stored under rather than a web address, so the file stays reachable whichever storage the marketplace is configured to use.

## Order

The gallery is ordered, and every image holds a distinct place in it. Two images of the same listing never share a place, so the order a buyer sees is always definite.

A newly added image goes behind the ones already there. Removing an image does not renumber the ones that remain, and a later addition still goes to the back rather than filling the space left behind.

## Cover

One image in a gallery is the cover — the single photo that stands for the listing wherever only one can be shown. A listing holds at most one cover, and that limit holds however the images were created.

The cover is decided rather than chosen: the first image a listing receives becomes its cover, so a listing with images always has one. Later images do not. A seller may promote any image to cover, which stands the previous one down.

Removing the cover hands the slot to whichever image is now at the front of the gallery. Removing any other image leaves the cover as it was, and removing the last image leaves the listing with no images and no cover.
