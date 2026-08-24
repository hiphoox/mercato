---
type: domain
title: Listing Images
description: Business rules for a listing's image gallery — what it accepts, ordering, the cover image, and what removal frees.
tags: [domain, listings, images, media, gallery, uploads]
timestamp: 2026-08-24T00:00:00Z
---

A listing's images are its gallery: an ordered set of photos belonging to that listing alone. Each image records the key its file is stored under rather than a web address, so the file stays reachable whichever storage the marketplace is configured to use.

## What a gallery accepts

An image joins a gallery by being uploaded. The file itself is what is offered — there is no way to enter a gallery by naming a file that is already in storage, so an image record never points at bytes it did not put there.

Two limits apply, both set by the marketplace: which image types are allowed, and how large a file may be. A file past either limit is refused, and nothing is stored or recorded for it.

The type is judged from the file's own opening bytes rather than from the name it arrives under or from what the sender claims it is. Renaming a file does not change what it is, so it does not change whether it is accepted. A file whose bytes match no image format at all is refused on the same grounds.

Each upload is stored under its own key, so two files of the same name never displace one another, and the key always falls within the listing's own area of storage whatever the file was named.

## How many a gallery holds

The marketplace sets how few and how many images a listing may have. A gallery that is already full refuses another image.

The minimum applies from the moment a listing goes on offer: a listing showing fewer images than required cannot be published, and an image cannot be removed if doing so would drop a listing already on offer below the requirement. A draft is exempt while it is still being composed. Setting the minimum to none drops the requirement altogether, which is what a marketplace selling services or digital goods wants.

How many images a listing has is a fact about the listing rather than about who is asking, so these limits are counted the same way for everyone.

## Order

The gallery is ordered, and every image holds a distinct place in it. Two images of the same listing never share a place, so the order a buyer sees is always definite.

A newly added image goes behind the ones already there. Removing an image does not renumber the ones that remain, and a later addition still goes to the back rather than filling the space left behind.

## Cover

One image in a gallery is the cover — the single photo that stands for the listing wherever only one can be shown. A listing holds at most one cover, and that limit holds however the images were created.

The cover is decided rather than chosen: the first image a listing receives becomes its cover, so a listing with images always has one. Later images do not. A seller may promote any image to cover, which stands the previous one down.

Removing the cover hands the slot to whichever image is now at the front of the gallery. Removing any other image leaves the cover as it was, and removing the last image leaves the listing with no images and no cover.

## Removal

Removing an image also removes the file behind it, so a gallery never leaves stored bytes behind that nothing can reach.

Removing a listing removes its whole gallery the same way — every image and every file. A listing's images belong to that listing alone, so nothing else loses an image when one is removed.
