[
    // -----------------------------------------------------------
    /*  
         
        VERSION 2010-04-09
         
        NOTE: 
     
        -   MUST be used ONLY with MySQL 4.1+ as it requires subqueries
        -   $gv_sql must be defined appropriately
        -   -cattable will be required to be passed in all operations
         
        DESCRIPTION
            addSibling
                Adds an entry AFTER specified item, at the same depth
            addChild
                Adds a child to the specified item.
                Usually employed when there is no existing child.
            addRoot
                Adds a node at the root - at the end
            deleteNode
                Self-descriptive... DELETES the node and all it's child nodes.
            moveNode
                Self-descriptive... MOVES the node and all it's child nodes in the specified direction.
            moveNodeTo
                Moves given node + nested nodes to inside a given node's id.
            fullCatSQL
                Returns the SQL required to extract the full tree.
            subTreeSQL
                Returns the SQL required to extract the tree branching from a specified node.
            showPathSQL
                Returns the SQL that will extract the linear path from the root to the node.
            getParent
                Returns a map, id and parentname
            getURLpath
                Returns the url page like /hello/world/ from an id
         
        USAGE:
        xs_cat->(addSibling(-cattable='category',-txt='Hello World',-id=10));
        xs_cat->(addChild(-cattable='category',-txt='Hello World',-id=10));
        xs_cat->(deleteNode(-cattable='category',-id=10));
        xs_cat->(moveNode(-cattable='category',-id=10));
        xs_cat->(fullCatSQL(-cattable='category',-xtraReturn=',column1, column2',-xtraWhere='SQL statement here'));
        xs_cat->(subTreeSQL(-cattable='category',-depth=2,-relative=true,-xtraReturn=',column1, column2',-xtraWhere='SQL statement here'));
        xs_cat->(showPathSQL(-cattable='category',-xtraReturn=',column1, column2',-xtraWhere='SQL statement here'));
     
        CHANGES:
        2006-06-17
            Added order to fullcatSQL
             
        2010-04-09
            Converted to Lasso 9
    */
    // -----------------------------------------------------------
 
    define xs_cat => type {
 
        public addSibling(-cattable::string,-txt::string,-othersmap::map=map,-id::integer,-fieldname::string='name') => {
            // ADDS ENTRY AFTER ANOTHER CHILD, SAME LEVEL
             
            local(
                xtraFields = string, 
                xtraValues = string,
                uniqueSeed = lasso_uniqueid
                )
            if(#othersmap->size > 0) => {
                iterate(#othersmap,local(temp)) => {
                    #xtraFields += ','+#temp->name
                    #temp->value == 'NOW()' ? #xtraValues += ',NOW()' | #xtraValues += ',"'+#temp->value+'"'
                }
            }
            local(sSQL = '
                LOCK TABLE '+#cattable+' WRITE;
                 
                SELECT @myRight := rgt FROM '+#cattable+' WHERE id = '+#id+';
                 
                UPDATE '+#cattable+' SET rgt = rgt + 2 WHERE rgt > @myRight;
                UPDATE '+#cattable+' SET lft = lft + 2 WHERE lft > @myRight;
                 
                INSERT INTO '+#cattable+'('+#fieldname+', lft, rgt'+#xtraFields+',uniqueSeed) VALUES("'+(encode_sql(#txt))+'", @myRight + 1, @myRight + 2'+#xtraValues+',"'+#uniqueSeed+'");
                 
                UNLOCK TABLES;
            ');
            inline($gv_sql,-SQL=#sSQL) => {
                xs_iserror
                inline($gv_sql,-SQL='SELECT id FROM '+#cattable+' WHERE uniqueSeed = "'+#uniqueSeed+'" LIMIT 1') => {
                    records => {
                        return field('id')
                    }
                }
            }
        }
 
 
        public addChild(-cattable::string,-txt::string,-othersmap::map=map,-id::integer,-fieldname::string='name',-atend::boolean='false') => {
            // ADDS ENTRY NESTED INSIDE CAT WHERE NO CHILD EXISTS
            local(
                xtraFields = string, 
                xtraValues = string,
                uniqueSeed = lasso_uniqueid
                )
            if(#othersmap->size > 0) => {
                iterate(#othersmap,local(temp)) => {
                    #xtraFields += ','+#temp->name
                    #temp->value == 'NOW()' ? #xtraValues += ',NOW()' | #xtraValues += ',"'+#temp->value+'"'
                }
            }
            if(#atend == false) => {
                local(sSQL = '
                    LOCK TABLE '+#cattable+' WRITE;
                     
                    SELECT @myLeft := lft FROM '+#cattable+' WHERE id = '+#id+';
                     
                    UPDATE '+#cattable+' SET rgt = rgt + 2 WHERE rgt > @myLeft;
                    UPDATE '+#cattable+' SET lft = lft + 2 WHERE lft > @myLeft;
                     
                    INSERT INTO '+#cattable+'('+#fieldname+', lft, rgt'+#xtraFields+',uniqueSeed) VALUES("'+(encode_sql(#txt))+'", @myLeft + 1, @myLeft + 2'+#xtraValues+',"'+#uniqueSeed+'");
                     
                    UNLOCK TABLES;
                ')
            else
                local(sSQL = '
                    LOCK TABLE '+#cattable+' WRITE;
                     
                    SELECT @myRight := rgt FROM '+#cattable+' WHERE id = '+#id+';
                     
                    UPDATE '+#cattable+' SET rgt = rgt + 2 WHERE rgt >= @myRight;
                    UPDATE '+#cattable+' SET lft = lft + 2 WHERE lft >= @myRight;
                     
                    INSERT INTO '+#cattable+'('+#fieldname+', lft, rgt'+#xtraFields+',uniqueSeed) VALUES("'+(encode_sql(#txt))+'", @myRight, @myRight + 1'+#xtraValues+',"'+#uniqueSeed+'");
                     
                    UNLOCK TABLES;
                ')
            }
             
            inline($gv_sql,-SQL=#sSQL) => {
                xs_iserror
                inline($gv_sql,-SQL='SELECT id FROM '+#cattable+' WHERE uniqueSeed = "'+#uniqueSeed+'" LIMIT 1') => {
                    records => {
                        return field('id')
                    }
                }
            }
        }
 
 
        public addRoot(-cattable::string,-txt::string,-othersmap::map=map,-fieldname::string='name') => {
            // ADDS ROOT NODE AT END
            local(
                xtraFields = string, 
                xtraValues = string,
                uniqueSeed = lasso_uniqueid
                )
            if(#othersmap->size > 0) => {
                iterate(#othersmap,local(temp)) => {
                    #xtraFields += ','+#temp->name
                    #temp->value == 'NOW()' ? #xtraValues += ',NOW()' | #xtraValues += ',"'+#temp->value+'"'
                }
            }
 
            local(sSQL = '
                LOCK TABLE '+#cattable+' WRITE;
                 
                SELECT @myRight := rgt FROM '+#cattable+' ORDER BY rgt DESC LIMIT 1;
                 
                INSERT INTO '+#cattable+'('+#fieldname+', lft, rgt'+#xtraFields+',uniqueSeed) VALUES("'+(encode_sql(#txt))+'", @myRight + 1, @myRight + 2'+#xtraValues+',"'+#uniqueSeed+'");
                 
                UNLOCK TABLES;
            ')
             
            inline($gv_sql,-SQL=#sSQL) => {
                xs_iserror
                inline($gv_sql,-SQL='SELECT id FROM '+#cattable+' WHERE uniqueSeed = "'+#uniqueSeed+'" LIMIT 1') => {
                    records => {
                        return field('id')
                    }
                }
            }
        }
 
 
 
 
        public deleteNode(-cattable::string,-id::integer) => {
 
            // DELETE A NODE
            local(sSQL = '
                LOCK TABLE '+#cattable+' WRITE;
     
                SELECT @myLeft := lft, @myRight := rgt, @myWidth := rgt - lft + 1
                FROM '+#cattable+'
                WHERE id = '+#id+';
                 
                DELETE FROM '+#cattable+' WHERE lft BETWEEN @myLeft AND @myRight;
                 
                UPDATE '+#cattable+' SET rgt = rgt - @myWidth WHERE rgt > @myRight;
                UPDATE '+#cattable+' SET lft = lft - @myWidth WHERE lft > @myRight;
                 
                UNLOCK TABLES;
            ')
            inline($gv_sql,-SQL=#sSQL) => {
                xs_iserror
            }
             
        }
 
 
        public moveNode(-cattable::string,-id::integer,-fieldname::string='name') => {
        /*
1       Calculate the branch width of the branch you want to move.
2       Update all lft and rgt values on the branch you want to move by multiplying them by -1.
3       Update all values on the tree as though the branch you just negated was deleted.
4       Update all lft values that are greater than the rgt value of the node you want to move the branch to by adding the branch width + 2 to them.
5       Update all rgt values that are greater than or equal to the rgt value of the node you want to move the branch to by adding the branch width + 2 to them.
6       Find the greatest negative lft value in the table, 
            which will be the top of the branch that you are moving, multiply it by -1 and call it x.
7       Find the lft value of the node that you want to attach the branch to, and call it y.
8       Calculate (y - x + 1) = z . Update all negative values in the table by subtracting z from them.
9       Update all negative values in the tree by multiplying them by -1.
        */
        local(id2 = 0)
        // get immediate prior sibling
        local(sSQL = (
                '
            SELECT node.id, node.'+#fieldname+', (COUNT(parent.id) - (sub_tree.depth + 1)) AS depth, node.lft, node.rgt
            FROM '+#cattable+' AS node,
                '+#cattable+' AS parent,
                '+#cattable+' AS sub_parent,
                (
                        SELECT node.'+#fieldname+', (COUNT(parent.id) - 1) AS depth
                        FROM '+#cattable+' AS node,
                        '+#cattable+' AS parent
                        WHERE node.lft BETWEEN parent.lft AND parent.rgt
                        AND node.id = 
                                (
                            SELECT parent.id
                            FROM '+#cattable+' AS node,
                            '+#cattable+' AS parent
                            WHERE node.lft BETWEEN parent.lft AND parent.rgt
                            AND node.id = '+#id+' AND parent.id != '+#id+'
                            ORDER BY parent.lft DESC LIMIT 1
                            )
                        GROUP BY node.'+#fieldname+'
                        ORDER BY node.lft
                )AS sub_tree
            WHERE node.lft BETWEEN parent.lft AND parent.rgt
                AND node.lft BETWEEN sub_parent.lft AND sub_parent.rgt
                AND sub_parent.'+#fieldname+' = sub_tree.'+#fieldname+'
            GROUP BY node.id
            HAVING depth = 1
            ORDER BY node.lft ASC;'
                ))
                inline($gv_sql,-SQL=#sSQL) => {
                    records => {
                        if(integer(field('id')) != #id) => {
                            #id2 = integer(field('id'))
                        else
                            loop_abort
                        }
                    }
                }
                 
                if(#id2 == 0) => {
                    // here we are trying to ascertain if it's a root node!
                    #sSQL = '
                        SELECT node.id, node.'+#fieldname+', (COUNT(parent.id) - 1) AS depth
                        FROM '+#cattable+' AS node,
                        '+#cattable+' AS parent
                        WHERE node.lft BETWEEN parent.lft AND parent.rgt
                        AND node.id = '+#id+'
                        GROUP BY node.id
                        ORDER BY node.lft'
                    inline($gv_sql,-SQL=#sSQL) => {
                        records => {
                            if(integer(field('depth')) == 0) => {
                                // yay, it's a root node!!!
                                #sSQL = '
                                    SELECT node.id, node.'+#fieldname+', (COUNT(parent.id) - 1) AS depth
                                    FROM '+#cattable+' AS node,
                                    '+#cattable+' AS parent
                                    WHERE node.lft BETWEEN parent.lft AND parent.rgt
                                    GROUP BY node.id
                                    HAVING depth = 0
                                    ORDER BY node.lft
                                '
                                inline($gv_sql,-SQL=#sSQL) => {
                                    records => {
                                        if(integer(field('id')) != #id) => {
                                            #id2 = integer(field('id'))
                                        else
                                            loop_abort
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                 
                if(#id2 > 0) => {
                #sSQL = ('
                    LOCK TABLE '+#cattable+' WRITE;
        -- 1            
                    SELECT @myLeft := lft, @myRight := rgt, @myWidth := rgt - lft + 1 FROM '+#cattable+' WHERE id = '+#id2+';
        -- 2                    
                    UPDATE '+#cattable+' SET rgt = (rgt*-1), lft = (lft*-1) WHERE lft BETWEEN @myLeft AND @myRight;
        -- 3        
                    UPDATE '+#cattable+' SET rgt = rgt - @myWidth WHERE rgt > @myRight;
                    UPDATE '+#cattable+' SET lft = lft - @myWidth WHERE lft > @myRight;
        -- 4a
                    SELECT @myLeft2 := lft, @myRight2 := rgt, @myWidth2 := rgt - lft + 1 FROM '+#cattable+' WHERE id = '+#id+';
        -- 4 & 5            
                    UPDATE '+#cattable+' SET rgt = rgt + @myWidth WHERE rgt > @myRight2;
                    UPDATE '+#cattable+' SET lft = lft + @myWidth WHERE lft > @myRight2;
        -- 6
        --          SELECT @x := (@myRight2 + 1) - (lft * -1) FROM '+#cattable+' WHERE id = '+#id+';
                    SELECT @x := lft FROM '+#cattable+' WHERE id = '+#id+';
                    SELECT @y := rgt FROM '+#cattable+' WHERE id = '+#id+';
        -- 8
                    UPDATE '+#cattable+' SET rgt = (rgt - (@y - @x + 1)) WHERE rgt < 0;
                    UPDATE '+#cattable+' SET lft = (lft - (@y - @x + 1)) WHERE lft < 0;
         
                    UPDATE '+#cattable+' SET rgt = rgt * -1 WHERE rgt < 0;
                    UPDATE '+#cattable+' SET lft = lft * -1 WHERE lft < 0;
         
                    UNLOCK TABLES;
                ')
                inline($gv_sql,-SQL=#sSQL) => { xs_iserror }
            }
        }
 
        public moveNodeTo(-cattable::string,-id::integer,-newparent::integer) => {
 
            local(sSQL = string);
 
            if(#newparent > 0 && #id > 0) => {
                #sSQL = ('
                    LOCK TABLE '+#cattable+' WRITE;
        -- 1    , get boundaries of chunk to move
                    SELECT @myLeft := lft, @myRight := rgt, @myWidth := rgt - lft + 1 FROM '+#cattable+' WHERE id = '+#id+';
         
        -- 2    , make chunk negative (ie move outta da way)        
                    UPDATE '+#cattable+' SET rgt = ((rgt-@myRight)-1), lft = ((lft-@myRight)-1) WHERE lft BETWEEN @myLeft AND @myRight;
         
        -- 3    , collapse
                    UPDATE '+#cattable+' SET rgt = rgt - @myWidth WHERE rgt > @myRight;
                    UPDATE '+#cattable+' SET lft = lft - @myWidth WHERE lft > @myRight;
 
        -- 4, get boundaries of new parent
                    SELECT @myRight2a := rgt FROM '+#cattable+' WHERE id = '+#newparent+';
                                         
        -- 5    , expand new parent + others to hold content
                    UPDATE '+#cattable+' SET rgt = rgt + @myWidth WHERE rgt >= @myRight2a; -- note >= is new addition
                    UPDATE '+#cattable+' SET lft = lft + @myWidth WHERE lft > @myRight2a;
 
        -- 6, get boundaries of new parent
                    SELECT @myLeft2 := lft, @myRight2 := rgt, @myWidth2 := rgt - lft + 1 FROM '+#cattable+' WHERE id = '+#newparent+';
 
         
        -- 8, take all less than 0 and ad myRight2, puts it automagically in teh right pos
                    UPDATE '+#cattable+' SET rgt = (rgt + @myRight2) WHERE rgt < 0;
                    UPDATE '+#cattable+' SET lft = (lft + @myRight2) WHERE lft < 0;
                     
                    UNLOCK TABLES;
                ')
                inline($gv_sql,-SQL=#sSQL) => { xs_iserror }
            }
        }
 
 
        public fullCatSQL(
            -cattable::string,
            -xtraReturn::string='',
            -xtraWhere::string='',
            -orderby::string='',
            -depth::integer=0,
            -fieldname::string='name'
            ) => {
 
            local(depthComp = string)
            #depth > 0 ? #depthComp = 'HAVING depth <= '+#depth
             
             
            local(orderComp = 'node.lft')
            #orderby->size > 0 ? #orderComp = #orderby
             
            /*
                Returns full category list incl depth.
                To specify additional columns returned use xtraReturn parameter
                To specify additional restrictions in WHERE clause, use xtraWhere parameter
                 
                An example of xtraReturn is as follows:
',
    (
        SELECT COUNT(*)
            FROM asset, category AS subc
            WHERE asset.category_id = subc.id
            AND subc.lft BETWEEN node.lft AND node.rgt
    )AS chqty,
    (
    SELECT COUNT(asset.name) FROM asset WHERE asset.category_id = node.id
    )AS qty,
    (
        SELECT COUNT(*) - 1
        FROM category AS nnode
        WHERE nnode.lft BETWEEN node.lft AND node.rgt
    )AS nchild'             
            */
            return ('
                SELECT 
                    node.id, node.'+#fieldname+', (COUNT(parent.id) - 1) AS depth '+#xtraReturn+'
                FROM '+#cattable+' AS node,
                '+#cattable+' AS parent
                WHERE node.lft BETWEEN parent.lft AND parent.rgt '+#xtraWhere+'
                GROUP BY node.id
                '+#depthComp+'
                ORDER BY '+#orderComp)
 
        }
 
 
        public subTreeSQL(
            -cattable::string,
            -id::integer,
            -xtraReturn::string='',
            -xtraWhere::string='',
            -relative::boolean=false,
            -depth::integer=0,
            -fieldname::string='name'
            ) => {
 
            #relative == false ? local('relatives' = '1') | local('relatives' = '(sub_tree.depth + 1)')
            local(depthComp = string)
            #depth > 0 ? #depthComp = 'HAVING depth <= '+#depth
 
            //(sub_tree.depth + 1) - makes the depth relative to the one requested
            //HAVING depth <= 1 - limits how many subs it pulls in
 
/*
================================================================================
From Pier 23/05/2006 16:26
 
Added node.id to the nested SELECT so that we can replace
    [...] sub_parent.name = sub_tree.name [...]
with 
    [...] sub_parent.id = sub_tree.id [...]
================================================================================
*/
            local(out = 'SELECT node.id, node.'+#fieldname+', (COUNT(parent.id) - '+#relatives+') AS depth '+#xtraReturn+'
                FROM '+#cattable+' AS node,
                        '+#cattable+' AS parent,
                        '+#cattable+' AS sub_parent,
                        (
                                SELECT node.id, node.'+#fieldname+', (COUNT(parent.id) - 1) AS depth
                                FROM '+#cattable+' AS node,
                                '+#cattable+' AS parent
                                WHERE node.lft BETWEEN parent.lft AND parent.rgt
                                AND node.id = '+#id+'
                                GROUP BY node.'+#fieldname+'
                                ORDER BY node.lft
                        )AS sub_tree
                WHERE node.lft BETWEEN parent.lft AND parent.rgt
                        AND node.lft BETWEEN sub_parent.lft AND sub_parent.rgt
                        AND sub_parent.id = sub_tree.id '+#xtraWhere+'
                GROUP BY node.id
                '+#depthComp+'
                ORDER BY node.lft
                ;')
            return #out
        }
         
 
 
        public showPathSQL(
            -cattable::string,
            -id::integer,
            -xtraReturn::string='',
            -xtraWhere::string='',
            -fieldname::string='name'
            ) => {
 
            local(out = 'SELECT node.id, node.'+#fieldname+', (COUNT(parent.id) - 1) AS depth '+#xtraReturn+'
    FROM '+#cattable+' AS node,
            '+#cattable+' AS parent,
            (
                SELECT sub.lft AS sublft, sub.rgt AS subrgt
                FROM '+#cattable+' AS sub
                WHERE sub.id = '+#id+'
            ) AS sub
    WHERE 
            node.lft <= sub.sublft
        AND     node.rgt >= sub.subrgt
        AND node.lft BETWEEN parent.lft AND parent.rgt '+#xtraWhere+'
    GROUP BY node.id
    ORDER BY node.lft
                ;')
                return #out
        }
         
        public getParent(
            -cattable::string,
            -id::integer,
            -xtraWhere::string='',
            -fieldname::string='name',
            -fieldurl::string='page_url'
            ) => {
 
            local(out = map)
            local(sSQL = 'SELECT 
                    parent.id,parent.'+#fieldname+',parent.'+#fieldurl+'
                FROM 
                    '+#cattable+' AS node,
                    '+#cattable+' AS parent
                WHERE 
                    node.lft BETWEEN parent.lft AND parent.rgt
                    AND node.id = '+#id+'
                    AND parent.id != node.id
                    '+#xtraWhere+'
                ORDER BY 
                    parent.lft DESC
                LIMIT 1')
            inline($gv_sql,-SQL=#sSQL) => {
                records => {
                    #out->insert('id'=field('id'),'parentname'=field(#fieldname),'page_url'=field(#fieldurl))
                }
            }
            return #out
        }       
        public getParentId(
            -cattable::string,
            -id::integer,
            -xtraWhere::string=''
            ) => {
 
            local(out = integer)
            local(sSQL = 'SELECT 
                    parent.id
                FROM 
                    '+#cattable+' AS node,
                    '+#cattable+' AS parent
                WHERE 
                    node.lft BETWEEN parent.lft AND parent.rgt
                    AND node.id = '+#id+'
                    AND parent.id != node.id
                    '+#xtraWhere+'
                ORDER BY 
                    parent.lft DESC
                LIMIT 1')
            inline($gv_sql,-SQL=#sSQL) => {
                records => {
                    return integer(field('id'))
                }
            }
            return 0
        }       
         
         
        public getURLpath(
            -cattable::string,
            -id::integer,
            -fieldurl::string='page_url'
            ) => {
 
 
            local(out = '/')
            local(sSQL = '
                SELECT node.id, node.'+#fieldurl+', (COUNT(parent.id) - 1) AS depth 
                FROM '+#cattable+' AS node,
                       '+#cattable+'  AS parent,
                        (
                            SELECT sub.lft AS sublft, sub.rgt AS subrgt
                            FROM '+#cattable+' AS sub
                            WHERE sub.id = '+#id+'
                        ) AS sub
                WHERE 
                        node.lft <= sub.sublft
                    AND     node.rgt >= sub.subrgt
                    AND node.lft BETWEEN parent.lft AND parent.rgt 
                GROUP BY node.id
                ORDER BY node.lft')
            inline($gv_sql,-SQL=#sSQL) => {
                records => {
                    #out += field(#fieldurl) + '/'
                }
            }
            return #out
        }   
         
    }
]