xs_cat
======

Lasso Implementation of Modified Preorder Tree Transversal

Member tags:
------------
```
.addSibling
// Adds an entry AFTER specified item, at the same depth
 
addChild
// Adds a child to the specified item.
// Usually employed when there is no existing child.
 
deleteNode
// Self-descriptive... DELETES the node and all it's child nodes.
 
moveNode
// Self-descriptive... MOVES the node and all it's child nodes in the specified direction.
 
fullCatSQL
// Returns the SQL required to extract the full tree.
 
subTreeSQL
// Returns the SQL required to extract the tree branching from a specified node.
 
showPathSQL
// Returns the SQL that will extract the linear path from the root to the node.
 
getParent
// Returns a map with the parent id and name
```

Database
--------
``` sql
CREATE TABLE `nestedset` (
`id` int(11) NOT NULL auto_increment,
`name` varchar(64) collate utf8_bin NOT NULL default '',
`lft` int(11) NOT NULL default '0',
`rgt` int(11) NOT NULL default '0',
`status` int(2) NOT NULL default '1',
PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_bin
```

Usage
-----
``` lasso
xs_cat->(addSibling(-cattable='category',-txt='Hello World',-id=10))
xs_cat->(addChild(-cattable='category',-txt='Hello World',-id=10))
xs_cat->(deleteNode(-cattable='category',-id=10))
xs_cat->(moveNode(-cattable='category',-id=10))
xs_cat->(fullCatSQL(-cattable='category',-xtraReturn=',column1, column2',-xtraWhere='SQL statement here'))
xs_cat->(subTreeSQL(-cattable='category',-depth=2,-relative=true,-xtraReturn=',column1, column2',-xtraWhere='SQL statement here'))
xs_cat->(showPathSQL(-cattable='category',-id=3,-xtraReturn=',column1, column2',-xtraWhere='SQL statement here',-fieldname='name'))
```
