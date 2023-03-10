/*	Question Set 1 - Easy */

/* Q1: Who is the senior most employee based on job title? */

select * from employee
order by levels desc
limit 1;

/* Q2: Which countries have the most Invoices? */
select billing_country AS COUNTRY,count(*) as NO_OF_INVOICES from invoice
group by billing_country
order by count(*) desc;

/* Q3: What are top 3 values of total invoice? */
SELECT INVOICE_ID,TOTAL FROM INVOICE
ORDER BY TOTAL DESC
LIMIT 3;

/* Q4: Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals */
select billing_city,sum(total) as invoice_total from invoice
group by billing_city
order by sum(total) desc
limit 1;

/* Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money.*/
select c.customer_id as customer_identity,c.first_name as FNAME,c.last_name as LNAME,sum(total) AS TOTAL_INVOICE from customer as c
join invoice as i
on i.customer_id=c.customer_id
group by c.customer_id
order by sum(total) desc
limit 1;

/*Q6:Get the details(id,full name,title,city,state,phone,email) of employees with the lowest level(consider lowest level of working to be L1) of working in the organisation */
select employee_id,concat(first_name,' ',last_name),title,city,state,phone,email from employee
where levels='L1';

/*Q7: HANDLE THE NULL VALUES PRESENT IN THE TABLE CUSTOMER AS PER COLUMNS NEEDS.*/
UPDATE CUSTOMER 
SET POSTAL_CODE=8320000
WHERE POSTAL_CODE IS NULL;
UPDATE CUSTOMER 
SET FAX='NOT AVAILABLE'
WHERE FAX IS NULL;
UPDATE CUSTOMER 
SET STATE='NOT AVAILABLE'
WHERE STATE IS NULL;
UPDATE CUSTOMER 
SET COMPANY='NOT AVAILABLE'
WHERE COMPANY IS NULL;

SELECT * FROM CUSTOMER;

/*Q8:Which top 10 countries have highest total_invoice.*/
select billing_country as COUNTRY_NAME, sum(total) as TOTAL_INVOICE from invoice
group by billing_country
order by sum(total) DESC
LIMIT 10;

/*Q9:Update the null values present in table track and get the details of track with the highest song length.show song length in minutes.*/
update track
set composer='OTHER'
where composer is null;
select track_id,name,composer,(milliseconds/60000) as song_length from track 
order by (milliseconds/60000) desc
limit 1;

/*Q10:Get the details of track that take memory more than the average memory of all the tracks.*/
select track_id,name,composer,bytes as memory from track
where bytes > (select avg(bytes) from track)
order by bytes desc;





/* Question Set 2 - Moderate */

/* Q1: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */

SELECT DISTINCT EMAIL , C.FIRST_NAME AS FNAME,C.LAST_NAME AS LNAME FROM CUSTOMER AS C
JOIN INVOICE AS I
ON I.INVOICE_ID=C.CUSTOMER_ID
JOIN INVOICE_LINE AS IL
ON IL.INVOICE_ID=I.INVOICE_ID
WHERE IL.TRACK_ID IN
(
SELECT TRACK_ID FROM TRACK AS T
JOIN GENRE AS G
ON T.GENRE_ID=G.GENRE_ID
WHERE G.NAME LIKE 'Rock'
	)
ORDER BY EMAIL ASC;


/* Q2: Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */
SELECT A.ARTIST_ID,A.NAME,COUNT(*) FROM ARTIST AS A
JOIN ALBUM AS AL
ON AL.ARTIST_ID=A.ARTIST_ID
JOIN TRACK AS T 
ON T.ALBUM_ID=AL.ALBUM_ID
WHERE TRACK_ID IN
(
SELECT TRACK_ID FROM TRACK AS T
JOIN GENRE AS G 
ON T.GENRE_ID=G.GENRE_ID
WHERE G.NAME LIKE 'Rock')
GROUP BY A.ARTIST_ID
ORDER BY COUNT(*) DESC
LIMIT 10;

/* Q3: Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */

SELECT name,milliseconds as track_length FROM TRACK
where milliseconds > (select avg(milliseconds) as avg_song_length from track)
order by milliseconds desc;

/*Q4:get the details(name of customer, genre name )of genre on which customer has spent the most. Also display the total amount spent on that genre.*/
select concat(c.first_name,' ',c.last_name),g.name,sum(il.unit_price*il.quantity) from invoice_line as il
join invoice as i on i.invoice_id=il.invoice_id
join customer as c on c.customer_id=i.customer_id
join track as t on t.track_id=il.track_id
join genre as g on g.genre_id=t.genre_id
group by 1,2
order by 3 desc;




/* Question Set 3 - Advance */

/* Q1: Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent */

/* Steps to Solve: First, find which artist has earned the most according to the InvoiceLines. Now use this artist to find 
which customer spent the most on this artist. For this query, you will need to use the Invoice, InvoiceLine, Track, Customer, 
Album, and Artist tables. Note, this one is tricky because the Total spent in the Invoice table might not be on a single product, 
so you need to use the InvoiceLine table to find out how many of each product was purchased, and then multiply this by the price
for each artist. */
with BSA as (
select a.artist_id, a.name as artist_name, sum(il.unit_price*il.quantity) as total_sales from invoice_line as il
join track as t
on t.track_id=il.track_id
join album as al
on al.album_id=t.album_id
join artist as a
on a.artist_id=al.artist_id
group by 1
order by 3 desc
limit 1
)
select c.customer_id,c.first_name,c.last_name,BSA.artist_name, sum(il.quantity*il.unit_price) as amount_spent from invoice as i
join customer as c
on c.customer_id=i.customer_id
join invoice_line as il
on il.invoice_id=i.invoice_id
join track as t
on t.track_id=il.track_id
join album as al
on al.album_id=t.album_id
join BSA 
on BSA.artist_id=al.artist_id
group by 1,2,3,4
order by 5 desc;


/* Q2: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */

/* Steps to Solve:  There are two parts in question- first most popular music genre and second need data at country level. */

/* Method : Using CTE */
WITH popular_genre AS 
(
    SELECT COUNT(invoice_line.quantity) AS purchases, customer.country, genre.name, genre.genre_id, 
	ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo 
    FROM invoice_line 
	JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
	JOIN customer ON customer.customer_id = invoice.customer_id
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN genre ON genre.genre_id = track.genre_id
	GROUP BY 2,3,4
	ORDER BY 2 ASC, 1 DESC
)
SELECT * FROM popular_genre WHERE RowNo <= 1;




