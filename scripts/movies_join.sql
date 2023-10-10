-- ** Movie Database project. See the file movies_erd for table\column info. **

-- 1. Give the name, release year, and worldwide gross of the lowest grossing movie.
SELECT s.film_title, s.release_year, r.worldwide_gross
FROM specs AS s
INNER JOIN revenue AS r
USING (movie_id)
ORDER BY r.worldwide_gross ASC
LIMIT 1;

-- ANSWER: Semi-Tough, 1977, 37187139

-- 2. What year has the highest average imdb rating?
SELECT s.release_year
FROM specs AS s
INNER JOIN rating AS r
USING (movie_id)
ORDER BY r.imdb_rating DESC
LIMIT 1;

-- 2008

-- 3. What is the highest grossing G-rated movie? Which company distributed it?

SELECT s.film_title, r.worldwide_gross, d.company_name
FROM revenue AS r
INNER JOIN specs AS s
USING (movie_id)
INNER JOIN distributors AS d
ON d.distributor_id = s.domestic_distributor_id
WHERE s.mpaa_rating = 'G'
ORDER BY r.worldwide_gross DESC
LIMIT 1;

-- ANSWER: TOY STORY 4 BY WALT DISNEY

-- 4. Write a query that returns, for each distributor in the distributors table, the distributor name and the number of movies associated with that distributor in the movies table. Your result set should include all of the distributors, whether or not they have any movies in the movies table.

SELECT d.company_name AS distributor, COUNT(s.film_title) AS films
FROM distributors AS d
LEFT JOIN specs AS s
ON d.distributor_id = s.domestic_distributor_id
GROUP BY d.company_name;

-- 5. Write a query that returns the five distributors with the highest average movie budget.

SELECT d.company_name AS distributor, AVG(r.film_budget) AS avg_budget
FROM revenue AS r
INNER JOIN specs AS s
USING (movie_id)
INNER JOIN distributors AS d
ON s.domestic_distributor_id = d.distributor_id
GROUP BY d.company_name
ORDER BY avg_budget DESC
LIMIT 5;

--ANSWER: Walt Disney, Sony Pictures, Lionsgate, DreamWorks, Warner Bros.

-- 6. How many movies in the dataset are distributed by a company which is not headquartered in California? Which of these movies has the highest imdb rating?

SELECT s.film_title, d.company_name AS distributor, d.headquarters, r.imdb_rating
FROM distributors AS d
INNER JOIN specs AS s
ON distributor_id = domestic_distributor_id
INNER JOIN rating AS r
USING (movie_id)
WHERE d.headquarters NOT LIKE '%, CA'
ORDER BY r.imdb_rating DESC;

-- ANSWER: 	Two & Dirty Dancing 

-- 7. Which have a higher average rating, movies which are over two hours long or movies which are under two hours?

SELECT 
	AVG(CASE WHEN s.length_in_min > 120 THEN r.imdb_rating END) AS over_2_,
	AVG(CASE WHEN s.length_in_min < 120 THEN r.imdb_rating END) AS under_2_
FROM specs AS s 
INNER JOIN rating AS r
USING (movie_id);
	
-- ANSWER: Movies Over 2 hours


-- ## Joins Exercise Bonus Questions

-- 1.	Find the total worldwide gross and average imdb rating by decade. 

--Then alter your query so it returns JUST the second highest average imdb rating and its decade. This should result in a table with just one row.

--PT 1
SELECT 
	(s.release_year/10)*10 AS decade,
	AVG(r.imdb_rating) AS avg_imdb_rating,
	AVG(r2.worldwide_gross) AS avg_gross
FROM rating AS r
INNER JOIN specs AS s
USING (movie_id)
INNER JOIN revenue AS r2
USING (movie_id)
GROUP BY (s.release_year/10)*10
ORDER BY avg_imdb_rating DESC;

--PT 2 
SELECT 
	(s.release_year/10)*10 AS decade,
	AVG(r.imdb_rating) AS avg_imdb_rating,
	AVG(r2.worldwide_gross) AS avg_gross
FROM rating AS r
INNER JOIN specs AS s
USING (movie_id)
INNER JOIN revenue AS r2
USING (movie_id)
GROUP BY (s.release_year/10)*10
ORDER BY avg_imdb_rating DESC
LIMIT 1 OFFSET 1;

-- 2.	Our goal in this question is to compare the worldwide gross for movies compared to their sequels.  

-- 	a.	Start by finding all movies whose titles end with a space and then the number 2.  

SELECT s.film_title
FROM specs AS s
	WHERE s.film_title LIKE '% 2';

-- 	b.	For each of these movies, create a new column showing the original film’s name by removing the last two characters of the film title. For example, for the film “Cars 2”, the original title would be “Cars”. Hint: You may find the string functions listed in Table 9-10 of https://www.postgresql.org/docs/current/functions-string.html to be helpful for this. 

SELECT 
	s.film_title, 
	REPLACE(s.film_title, '2', ' ') AS original
FROM specs AS s
	WHERE s.film_title LIKE '% 2';
	
-- 	c.	Bonus: This method will not work for movies like “Harry Potter and the Deathly Hallows: Part 2”, where the original title should be “Harry Potter and the Deathly Hallows: Part 1”. Modify your query to fix these issues.  

SELECT 
	s.film_title, 
	REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE
							(s.film_title, '2', '')
							, '- Part', ''), 
							'Vol.', ''),
							': Part', ''),
							': Mockingjay', ''),
							': Breaking Dawn', ''),
							'and the Deathly Hallows', '')
			AS original_title
FROM specs AS s
	WHERE s.film_title LIKE '% 2';

-- 	d.	Now, build off of the query you wrote for the previous part to pull in worldwide revenue for both the original movie and its sequel. 
--Do sequels tend to make more in revenue? Hint: You will likely need to perform a self-join on the specs table in order to get the movie_id values for both the original films and their sequels. 

CREATE TABLE original_movie_titles AS  -- CREATED TABLE WITH ORIGINAL TITLES
SELECT 
	REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE
							(s.film_title, '2', '')
							, '- Part', ''), 
							'Vol.', ''),
							': Part', ''),
							': Mockingjay', ''),
							': Breaking Dawn', ''),
							'and the Deathly Hallows', '')
			AS original_title
FROM specs AS s
	WHERE s.film_title LIKE '% 2';

--- INNER JOIN ON ORIGINALS & SEQUELS
--Bonus: A common data entry problem is trailing whitespace. In this dataset, it shows up in the film_title field, where the movie “Deadpool” is recorded as “Deadpool “. One way to fix this problem is to use the TRIM function. Incorporate this into your query to ensure that you are matching as many sequels as possible.

SELECT
    s2.movie_id,
    TRIM(TRAILING ' ' FROM original_title) AS original_film,
    r.worldwide_gross
FROM original_movie_titles
LEFT JOIN specs AS s
    ON TRIM(TRAILING ' ' FROM original_title) = TRIM(TRAILING ' ' FROM s.film_title)
LEFT JOIN revenue AS r
    ON s.movie_id = r.movie_id
LEFT JOIN specs AS s2
    ON s.movie_id = s2.movie_id
WHERE TRIM(TRAILING ' ' FROM original_title) IN (
    'Incredibles',
    'Deadpool',
    'Wolf Warrior',
    'Guardians of the Galaxy',
    'The Hunger Games',
    'The Amazing Spider-Man',
    'Despicable Me',
	'The Twilight Saga',
	'Harry Potter',
	'Kung Fu Panda',
	'Cars',
	'Iron Man',
	'Shrek',
	'Spider-Man',
	'Toy Story',
	'Die Hard',
	'Lethal Weapon',
	'Jaws'
);

--STILL WORKING BUT PAUSING NOW

-- 3.	Sometimes movie series can be found by looking for titles that contain a colon. For example, Transformers: Dark of the Moon is part of the Transformers series of films.  
-- 	a.	Write a query which, for each film will extract the portion of the film name that occurs before the colon. For example, “Transformers: Dark of the Moon” should result in “Transformers”.  If the film title does not contain a colon, it should return the full film name. For example, “Transformers” should result in “Transformers”. Your query should return two columns, the film_title and the extracted value in a column named series. Hint: You may find the split_part function useful for this task.

SELECT 
	film_title, 
	SPLIT_PART(film_title,':',1) AS extracted_title
FROM specs;

-- 	b.	Keep only rows which actually belong to a series. Your results should not include “Shark Tale” but should include both “Transformers” and “Transformers: Dark of the Moon”. Hint: to accomplish this task, you could use a WHERE clause which checks whether the film title either contains a colon or is in the list of series values for films that do contain a colon.  

SELECT 
	film_title, 
	SPLIT_PART(film_title,':',1) AS extracted_title
FROM specs
	WHERE film_title LIKE '%:%'
ORDER BY film_title;

-- 	c.	Which film series contains the most installments?  
--ANSWER: STAR WARS

SELECT 
	SPLIT_PART(film_title,':',1) AS extracted_title,
	COUNT(film_title) AS film_title
FROM specs
	WHERE film_title LIKE '%:%'
GROUP BY extracted_title
ORDER BY film_title DESC;

-- 	d.	Which film series has the highest average imdb rating? Which has the lowest average imdb rating?
--ANSWER: Highest - The Lord of the Rings, Lowest --The Twilight Saga
SELECT 
	SPLIT_PART(film_title,':',1) AS extracted_title,
	COUNT(film_title), 
	AVG(imdb_rating) AS avg_imdb
FROM specs
INNER JOIN rating
USING (movie_id)
	WHERE film_title LIKE '%:%'
GROUP BY extracted_title
ORDER BY avg_imdb DESC;

-- 4.	How many film titles contain the word “the” either upper or lowercase? How many contain it twice? three times? four times? Hint: Look at the sting functions and operators here: https://www.postgresql.org/docs/current/functions-string.html 

SELECT LOWER(film_title),regexp_count(LOWER(film_title), 'the') AS num_the
FROM specs
WHERE LOWER(film_title) LIKE '%the%'
	ORDER BY num_the DESC;

--ANSWER 1: 146 titles contain the word 'the'
--ANSWER 2: 12 titles contain the word 'the' twice
--Answer 3: 3 titles contain the word 'the' three times
--Answer 4: 3 titles contain the word 'the' four times

-- 5.	For each distributor, find its highest rated movie. Report the company name, the film title, and the imdb rating. Hint: you may find the LATERAL keyword useful for this question. This keyword allows you to join two or more tables together and to reference columns provided by preceding FROM items in later items. See this article for examples of lateral joins in postgres: https://www.cybertec-postgresql.com/en/understanding-lateral-joins-in-postgresql/ 

SELECT DISTINCT(d.company_name), s.film_title, ra.imdb_rating
FROM distributors AS d
JOIN specs AS s
ON d.distributor_id = domestic_distributor_id
LEFT JOIN LATERAL (
	SELECT r.imdb_rating
	FROM rating AS r
	WHERE r.movie_id = s.movie_id
) AS ra ON true
ORDER BY 
	ra.imdb_rating DESC;

--ANSWER:
---"Warner Bros."	"The Dark Knight"	9.0
---"New Line Cinema"	"The Lord of the Rings: The Return of the King"	8.9
---"Universal Pictures"	"Schindler's List"	8.9
---"New Line Cinema"	"The Lord of the Rings: The Fellowship of the Ring"	8.8
---"Paramount Pictures"	"Forrest Gump"	8.8

-- 6.	Follow-up: Another way to answer 5 is to use DISTINCT ON so that your query returns only one row per company. You can read about DISTINCT ON on this page: https://www.postgresql.org/docs/current/sql-select.html. 

SELECT DISTINCT ON (d.company_name) d.company_name, s.film_title, ra.imdb_rating
FROM distributors AS d
JOIN specs AS s ON d.distributor_id = s.domestic_distributor_id
LEFT JOIN LATERAL (
    SELECT r.imdb_rating
    FROM rating AS r
    WHERE r.movie_id = s.movie_id
) AS ra ON true
ORDER BY d.company_name, ra.imdb_rating DESC; -----NOT SURE WHY THIS DOESN'T MATCH MY ABOVE QUERY --

-- 7.	Which distributors had movies in the dataset that were released in consecutive years? For example, Orion Pictures released Dances with Wolves in 1990 and The Silence of the Lambs in 1991. Hint: Join the specs table to itself and think carefully about what you want to join ON. 

SELECT 
	COUNT(DISTINCT(s1.film_title)) AS films_that_year, 
	s1.release_year, 
	d.company_name AS distributor
FROM specs AS s1
LEFT JOIN specs AS s2
ON s1.release_year = s2.release_year
INNER JOIN distributors AS d
ON d.distributor_id = s1.domestic_distributor_id
GROUP BY s1.release_year, d.company_name
ORDER BY d.company_name ASC, s1.release_year ASC;----DID NOT GET THIS ONE COULDNT FIGURE OUT HOW TO ISOLATE CONSECT YEARS --

--ANSWER: COLUMBIA PICTURES, DREAMWORKS, LIONSGATE, METRO-GOLDWYN-MAYER, NEW LINE CINEMA, ORION, PARAMOUNT, SONY, SUMMIT,TRI-STAR, TWENTIETH CENTRUY FOX, UNIVERSAL PICTURES,WALT DISNEY, & WARNER BROS.