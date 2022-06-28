-- look at the first 10 rows in each table; customers, orders, and books
SELECT * FROM customers;
SELECT * FROM orders;
SELECT * FROM books;

--Examine the indexes that already exist on the three tables customers, books and orders. 
SELECT * FROM pg_Indexes 
WHERE tablename IN ( 'customers','books','orders');


/*
Your marketing team reaches out to you to request regular information on sales figures, 
but they are only interested in sales of greater than 18 units sold in an order to see 
if there would be a benefit in targeted marketing. 
They will need the customer_ids, and quantity ordered.
*/
--Perform an EXPLAIN ANALYZE when doing the SELECT function to get the information WHERE quantity > 18. 
--Take note of how long this select statement took without an index.
EXPLAIN ANALYZE SELECT customer_ids, quantity 
FROM orders WHERE quantity > 18;

--build an index to improve the search time for this specific query 
--Specifically where more than 18 books were ordered
CREATE INDEX orders_customer_ids_quantity_idx 
ON orders (customer_ids, quantity) 
WHERE quantity > 18;

/*
EXPLAIN ANALYZE query again, this time after your new index to compare the before and 
after of the impact of this query.
 Can you explain the change? As more orders are placed, would this difference 
 become greater or less noticeable? 
*/
EXPLAIN ANALYZE SELECT customer_ids, quantity 
FROM orders WHERE quantity > 18;


/*
You may have noticed that the customers table is missing a primary key, 
and therefore its accompanying index. Let’s create that primary key now.
*/
--since  the table and column already exist, add a table constraint
--postgres automatically creates the unique index `customers_pkey` for the primary key constaint 
ALTER TABLE customers ADD CONSTRAINT customers_pkey  
PRIMARY KEY (customer_id);

/*
To check the effectiveness of this index, write a query that uses a WHERE clause 
targeting the primary key field. Run this query before and after creating the index. 
You can add EXPLAIN ANALYZE to these queries to see how long they take with and without 
the index. Make sure that these two queries are identical — you want to
 make sure you’re using the same measuring stick before and after the index is created.
 */
DROP INDEX IF EXISTS customers_pkey;

--before index is created
EXPLAIN ANALYZE SELECT * 
FROM customers 
WHERE customer_id < 100;

--create index
CREATE INDEX  customers_pkey ON customers (customer_id);

--after index is created
EXPLAIN ANALYZE SELECT * FROM customers WHERE  customer_id < 100;

/*
You might have noticed that when you got the top 10 records from the customers table 
that they weren’t in numerical order by customer_id. This was intentionally done to 
simulate a system that has experienced updates, deletes, inserts from a live system. 
Use your new primary key to fix this so the system is ordered in the database physically
 by customer_id.
*/
CLUSTER customers USING customers_pkey;

/*
To verify this worked, you can query the first 10 rows of the customers table again 
to see the table organized by the primary key.
*/
SELECT * FROM customers LIMIT 10;

/*
Regular searches are done on the combination of customer_id and book_id on the 
orders table. You have determined (through testing) that this would be a good 
candidate to build a multicolumn index on. 
Let’s build this index!
*/
CREATE INDEX customers_customers_id_book_id_idx 
ON orders (customer_id,book_id) ;

/*
You notice that your queries using the index you just built are also regularly 
asking for the quantity ordered as well.Drop your previous index and recreate 
it to improve it for this new information.
*/
CREATE INDEX customers_customers_id_book_id_qty_idx 
ON orders (customer_id,book_id,quantity);

/* 
Recall the two indexes we investigated at the start of this project. They were built 
to try and improve the book overview page that allows users to search for a book by 
author or title. However, these searches are taking longer than you think they should. 
You already have indexes on the two main search criteria, author and title. 
What else could you do to improve the runtime (hint, you will be creating an index)?
*/
CREATE INDEX book_author_title_idx ON 
books (author,title);

/*
You notice the order history page taking longer than you would like for customer 
experiences. After some research, you notice the largest amount of time is spent 
calculating the total price the customer spent on each order. Let us set up a test.
 Write an EXPLAIN ANALYZE when looking for all the information on all orders where the 
 total price (quantity * price_base) is over 100.
*/
EXPLAIN ANALYZE SELECT *,(quantity * price_base) AS "total price" FROM orders 
WHERE (quantity * price_base) >100 ;


--Create an index to speed this query up (recall, total price is quantity * price_base).
CREATE INDEX orders_total_price_idx ON 
orders ((quantity*price_base));

/* 
investigate if your index has helped. Run your EXPLAIN ANALYZE again after your 
index is completed and compare the planning and execution times to see if this will 
help in this situation.
*/
EXPLAIN ANALYZE SELECT *,(quantity * price_base) AS "total price" FROM orders 
WHERE (quantity * price_base) >100 ;

