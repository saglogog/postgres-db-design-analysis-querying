/* 
	QUESTION 1.1. 
	Create the database based on the relational schema provided and load it using the data provided.
*/

/*
	creating table customers
*/
CREATE TABLE Customers (
	CUSTOMERID serial NOT NULL,
	FIRSTNAME TEXT NOT NULL,
	LASTNAME TEXT NOT NULL,
	ADDRESS1 TEXT NOT NULL,
	ADDRESS2 TEXT,
	CITY TEXT NOT NULL,
	STATE TEXT NOT NULL,
	ZIP TEXT NOT NULL,
	COUNTRY TEXT NOT NULL,
	REGION TEXT NOT NULL,
	EMAIL TEXT NOT NULL,
	PHONE TEXT NOT NULL,
	CREDITCARDTYPE INT NOT NULL,
	CREDITCARD TEXT NOT NULL,
	CREDITCARDEXPIRATION TEXT NOT NULL,
	USERNAME TEXT NOT NULL,
	PASSWORD TEXT NOT NULL,
	AGE SMALLINT NOT NULL,
	INCOME TEXT NOT NULL,
	GENDER TEXT NOT NULL,
	PRIMARY KEY (CUSTOMERID)
);

/*
	creating table categories
*/
CREATE TABLE Categories (
	CATEGORY INT NOT NULL,
	CATEGORYNAME TEXT NOT NULL,
    PRIMARY KEY (CATEGORY)
);

/*
	creating table orders
*/
CREATE TABLE Orders (
	ORDERID INT NOT NULL,
	ORDERDATE DATE NOT NULL,
	CUSTOMERID INTEGER NOT NULL references Customers(CUSTOMERID),
	NETAMOUNT MONEY NOT NULL,
	TAX MONEY NOT NULL,
	TOTALAMOUNT MONEY NOT NULL,
	PRIMARY KEY (ORDERID)	
);

/*
	creating table products
*/
CREATE TABLE Products (
	PROD_ID INT NOT NULL,
	CATEGORY INT NOT NULL references Categories (CATEGORY),
	TITLE TEXT NOT NULL,
	ACTOR TEXT NOT NULL,
	PRICE MONEY NOT NULL,
	PRIMARY KEY (PROD_ID)
);

/*
	creating table orderlines
*/
CREATE TABLE Orderlines (
	ORDERLINEID INT NOT NULL,
	ORDERID INT NOT NULL REFERENCES Orders(ORDERID),
	PROD_ID INT NOT NULL REFERENCES Products(PROD_ID),
	QUANTITY INT NOT NULL,
	ORDERDATE DATE NOT NULL,
	PRIMARY KEY (ORDERLINEID, ORDERID)
);

/*
	import tables from respective files
*/
COPY Categories FROM 'resources/data/categories.csv' DELIMITER ',' CSV HEADER;
COPY Customers FROM 'resources/data/customers.csv' DELIMITER ',' CSV HEADER;
COPY Orders FROM 'resources/data/orders.csv' DELIMITER ',' CSV HEADER;
COPY Products FROM 'resources/data/products.csv' DELIMITER ',' CSV HEADER;
COPY orderlines FROM 'resources/data/orderlines.csv' DELIMITER ',' CSV HEADER;


/*==============================================================================*/


/* 
	QUESTION 1.2. 
	Remodeling the database using the object-relational model, we:
		- create the composite types as needed for each object and
		- load the data to the appropriate table using PL/SQL functions.
*/


/* 1.2.1. CUSTOMERS PL/SQL SCRIPT */
/*------------------------------------------------------------------------------*/

/*	Type Customer_type */
create type Customer_type as(
	CUSTOMERID integer,
	FIRSTNAME TEXT,
	LASTNAME TEXT,
	ADDRESS1 TEXT,
	ADDRESS2 TEXT,
	CITY TEXT,
	STATE TEXT,
	ZIP TEXT,
	COUNTRY TEXT,
	REGION TEXT,
	EMAIL TEXT,
	PHONE TEXT,
	CREDITCARDTYPE INT,
	CREDITCARD TEXT,
	CREDITCARDEXPIRATION text,
	USERNAME TEXT,
	PASSWORD TEXT,
	AGE TEXT,
	INCOME TEXT,
	GENDER TEXT);

/* Table customer_rel from type Customer_type */
create table customer_rel of Customer_type
	(primary key (customerid));

/* Function that populates the table based on Customer_type */
CREATE FUNCTION create12() RETURNS void AS $$ 
	BEGIN
		INSERT INTO customer_rel
		SELECT * FROM customers;
	END;
$$ LANGUAGE plpgsql;


select create12();

/*------------------------------------------------------------------------------*/


/* 1.2.2. ORDERS PL/SQL SCRIPT */
/*------------------------------------------------------------------------------*/

/*	Type Order_type */
create type Order_type as(
	ORDERID INT,
	ORDERDATE DATE,
	CUSTOMERID INTEGER,
	NETAMOUNT MONEY,
	TAX MONEY,
	TOTALAMOUNT MONEY
 );

/* Table order_rel from type Order_type */
create table order_rel of Order_type
	(primary key (orderid),
	foreign key (customerid)
		references customer_rel (customerid));

/* Function that populates the table based on Order_type */
CREATE FUNCTION create13() RETURNS void AS $$ 
	BEGIN
		INSERT INTO order_rel 
		SELECT * FROM orders;
	END;
$$ LANGUAGE plpgsql;

Select create13();

/*------------------------------------------------------------------------------*/


/* 1.2.3. CATEGORY PL/SQL SCRIPT */
/*------------------------------------------------------------------------------*/

/*	Type Category_type */
create type Category_type as (
	CATEGORY INT,
	CATEGORYNAME TEXT
);

/* Table category_rel from type Category_type */
create table category_rel of Category_type
	(primary key (category));

/* Function that populates the table based on Category_type */
CREATE FUNCTION create10() RETURNS void AS $$ 
	BEGIN
		INSERT INTO category_rel 
		SELECT * FROM categories;
	END;
$$ LANGUAGE plpgsql;

Select create10();

/*------------------------------------------------------------------------------*/


/* 1.2.4. PRODUCT PL/SQL SCRIPT */
/*------------------------------------------------------------------------------*/

/*	Type Product_type */
create type Product_type as (
	PROD_ID INT,
	CATEGORY INT,
	TITLE TEXT,
	ACTOR TEXT,
	PRICE MONEY
);

/* Table product_rel from type Product_type */
create table product_rel of Product_type
	(primary key (prod_id),
	foreign key (category)
		references category_rel (category));

/* Function that populates the table based on Product_type */
CREATE FUNCTION create11() RETURNS void AS $$ 
	BEGIN
		INSERT INTO product_rel 
		SELECT * FROM products;
	END;
$$ LANGUAGE plpgsql;

Select create11();

/*------------------------------------------------------------------------------*/


/* 1.2.5. ORDERLINES PL/SQL SCRIPT */
/*------------------------------------------------------------------------------*/

/*	Type Orderline_type */
create type Orderline_type as (
	ORDERLINEID INT,
	ORDERID INT,
	PROD_ID INT,
	QUANTITY INT,
	ORDERDATE DATE
);

/* Table orderline_rel from type Orderline_type */
create table orderline_rel of Orderline_type(
	primary key (orderlineid, orderid),
	foreign key (orderid) references order_rel(orderid),
	foreign key (prod_id) references product_rel(prod_id)
	);

/* Function that populates the table based on Orderline_type */
CREATE FUNCTION create14() RETURNS void AS $$ 
	BEGIN
		INSERT INTO orderline_rel 
		SELECT * FROM orderlines;
	END;
$$ LANGUAGE plpgsql;

Select create14();

/*------------------------------------------------------------------------------*/


/*==============================================================================*/


/* 
	QUESTION 2.1. 
	Running Queries on the Relational Database:
		2.1.1. Find the products with the highest/lowest number of buyers,
		2.1.2. Find the customer that has made an order with the most distinct
		       DVD categories.

*/

/* 2.1.1. A. Finding the customer that has made an order with the HIGHEST
			 number of buyers. */

CREATE TEMP TABLE temp1 AS
	SELECT DISTINCT  orderlines.prod_id, orders.customerid
		FROM orderlines
	INNER JOIN orders
		ON orderlines.orderid = orders.orderid
	GROUP BY prod_id, customerid;

/*
	For starters we run the SELECT command and using the following JOIN we end up
	in temmporary table that has the prod_id and customer_id columns that interest us.
	Unfortunately that table has 60325 entries, while the starting entries in ORDELINES are
	60350. 
	This probably means that some products have been bought more than once by the same buyer.
	For this reason we add the distinct keyword, and save this table as temp1.
	Then, we want the all the customers (unique customer_id) that bougth a product to 
	that product's unique product_id.
*/

CREATE TEMP TABLE temp2 AS
	SELECT prod_id, count(*) 
		FROM temp1
	GROUP BY prod_id
	ORDER BY count,prod_id;

/*
	We end up with a table that has 9973 records which points out how many times the product
	has been bought (e.g. product w/ prod_id 1 has been bought 4 times etc.).
	So in order to find the product with the maximum amt of buyers we execute the following 
	commands:
*/

SELECT prod_id,count 
	FROM temp2 
	WHERE count=(SELECT max(count) FROM temp2); 
 
/*
	It appears that the product that has been bought the most times is the product
	w/ prod_id 3011 from 18 different buyers!
*/

/* 2.1.1. B. Finding the customer that has made an order with the LOWEST
			 number of buyers.

	If that means no buyers, it becomes obvious that in this table there are 
	9973 records, while we have 10000 unique products. This would mean that 
	there are 27 products that have been never bought. 
	To locate them we need only to scan the prd_id column to find the missing
	prd_ids:
*/

select s.i as missing_cmd
	from generate_series(1,10000) s(i)
	where not exists(select 1 from temp1 where prod_id = s.i);
 
/* 
	The resulting 27 products have the minimum number of buyers!
*/


/*
	In case minimum are considered the products that have been bought by at least on buyer
	and not those not bought at all, we use the min instead of the max keyword.
*/

SELECT prod_id,count 
	FROM temp2 
	WHERE count=(SELECT min(count) FROM temp2);
 
/* 
	As a result we get the 141 products that have only been bought once.
*/

/* The full query for the maximum amt of buyers is as follows: */

CREATE TEMP TABLE temp1 AS
	SELECT DISTINCT  orderlines.prod_id, orders.customerid
		FROM orderlines
	INNER JOIN orders
	ON orderlines.orderid = orders.orderid
	GROUP BY prod_id, customerid

CREATE TEMP TABLE temp2 AS
	SELECT prod_id, count(*) 
		FROM temp1
	GROUP BY prod_id
	order by count,prod_id;

SELECT prod_id,count 
	FROM temp2 
	WHERE count=(SELECT max(count) FROM temp2); 

/*
	The full query for the minimum amt of buyers is the following:
*/ 

CREATE TEMP TABLE temp1 AS
	SELECT DISTINCT  orderlines.prod_id, orders.customerid
		FROM orderlines
	INNER JOIN orders
		ON orderlines.orderid = orders.orderid
	GROUP BY prod_id, customerid

CREATE TEMP TABLE temp2 AS
	SELECT prod_id, count(*) 
		FROM temp1
	GROUP BY prod_id
	order by count,prod_id;

select s.i as missing_cmd
from generate_series(1,10000) s(i)
where not exists(select 1 from temp1 where prod_id = s.i);


/*------------------------------------------------------------------------------*/

/* 2.1.2. Finding the customer that has made an order with the most distinct
		  DVD categories. */

CREATE TEMP TABLE temp3 AS
	SELECT orderlines.prod_id, orders.customerid, products.category, orderlines.orderid
		FROM orderlines
	INNER JOIN orders
		ON orderlines.orderid = orders.orderid
	INNER JOIN products
		ON orderlines.prod_id = products.prod_id
	ORDER BY CUSTOMERID;

/*
	First we join the tables above and store the result in the temporary 
	table temp3. It becomes clear that some orderids have contain duplicate 
	(in this we mean different movies that belong to the same category). 
	These entries are removed as follows.
*/

CREATE TEMP TABLE temp4 AS
	SELECT DISTINCT  customerid, category, orderid
		FROM temp3 
	GROUP BY customerid, category, orderid
	ORDER BY customerid, orderid;

/* 	
	Using distinct, we remove the duplicate entries and we store the result in
	a new temporary table, temp 4. WNext we find how many different categories
	of movies exist each distinct orderid.
*/

CREATE TEMP TABLE temp5 AS 
	SELECT orderid, count(*),customerid 
		FROM temp4
	GROUP BY orderid, customerid
	ORDER BY count, orderid;

/*
	We store the result in a final temporary table, temp5, and then we find the
	orderid with the maximum categories.
*/

SELECT customerid, count, orderid
	FROM temp5
	WHERE count =(SELECT MAX(count) FROM temp5);

/*
	The result returns 71 rows which means that 71 buyers have made an order that 
	contains the maximum number of categories (9).
*/

/*------------------------------------------------------------------------------*/

/*==============================================================================*/
