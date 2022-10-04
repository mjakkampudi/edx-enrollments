-- (i) Create the edX database.

DROP DATABASE IF EXISTS `Edx_Courses`;
CREATE DATABASE  IF NOT EXISTS `Edx_Courses`;
USE `Edx_Courses`;


-- (ii)	Create a first table in this database that is exactly the same as the table in the csv file.
-- Assigning the name “information” to this table. Dumping data from the csv file into this table.


DROP TABLE IF EXISTS `information1`;
CREATE TABLE `information1` (
`Course_id` varchar(300) not null,
`Course_Short_Title` varchar(300) default null,
`Course_Long_Title` varchar(300) default null,
`Userid_DI` varchar(40) not null,
`Registered` int(11) default null,
`Viewed` int(11) default null,
`Explored` int(11) default null,
`Certified` int(11) default null,
`Country` varchar(300) default null,
`LoE_DI` varchar(300) default null,
`YoB` int default null,
`Age` int default null,
`Gender` varchar(300) default null,
`Grade` double default null,
`nevents` varchar(300) default null,
`ndays_act` varchar(300) default null,
`nplay_video` varchar(300) default null,
`nchapters` varchar(300) default null,
`nforum_posts` int default null,
`roles` varchar(300) default null,
`incomplete_flag` varchar(300) default null);
-- PRIMARY KEY (`Course_id`, `Userid_DI`));

LOCK TABLES `information1` WRITE;
-- LOAD DATA INFILE '/Users/monikajakkamputi/Desktop/EdxEnrollment.csv'
LOAD DATA INFILE '/tmp/EdxEnrollment.csv'
INTO TABLE information1
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
UNLOCK TABLES;

CREATE TABLE INFORMATION AS
Select `Course_id`, substring_index(Course_id, '/', 1) AS `Institution`,
substring_index(substring_index(Course_id, '/', 2),'/' , -1) AS `Course_number`,
substring_index(substring_index(Course_id, '/', 3), '/', -1)AS `Course_term`, `Course_Short_Title`,
`Course_Long_Title` ,
`Userid_DI` ,
`Registered` ,
`Viewed` ,
`Explored`,
`Certified`,
`Country` ,
`LoE_DI` ,
`YoB` ,
`Age` ,
`Gender`,
`Grade` ,
`nevents` ,
`ndays_act` ,
`nplay_video` ,
`nchapters`,
`nforum_posts` ,
`roles` ,
`incomplete_flag`
FROM information1;
Drop table information1;

-- (iii) Creating other tables that I have included in the design of my model.
-- Next, using the “information” table created above to dump data into each of the tables.


CREATE TABLE Course_Details as
SELECT distinct
`Course_id`,
`Course_number`,
`Institution`,
`Course_term`,
`Course_Short_Title` ,
`Course_Long_Title`
 FROM information;

 alter table  Course_Details
 add primary key(`Course_id` );

SET session sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));
CREATE TABLE User_Details as
SELECT distinct `Userid_DI`,
`Country`,
`LoE_DI` ,
`YoB` ,
`Age` ,
`Gender`
FROM information
group by Userid_DI;

alter table  User_Details
add primary key(`Userid_DI` );


CREATE TABLE  User_Course_Registration as
SELECT `Course_id`,
`Userid_DI`,
`Registered` ,
`Viewed` ,
`Explored` ,
`Certified`,
`Grade` ,
`nevents` ,
`ndays_act` ,
`nplay_video` ,
`nchapters` ,
`nforum_posts` ,
`roles`,
`incomplete_flag`
FROM information;

alter table User_Course_Registration
add foreign key (`Course_id`) references Course_Details(`Course_id`);

alter table User_Course_Registration
add foreign key (`Userid_DI`) references User_Details(`Userid_DI`);


--------------------------------------------
-- Answering some basic questions using SQL queries (showcasing usage of basic concepts in SQL)
--------------------------------------------


-- How many rows are there in the “information” table whose grades are not NULL?


SELECT  count(*)
from information
where Grade is not null;


--  Among the rows in the “information” table whose grades are not NULL,
--  list the countries with doctoral students; sorted by country.


SELECT  distinct country
from information
where Grade is not null
and LoE_DI = 'Doctorate'
order by country;


-- How many students were registered in 6.00x at MIT during fall 2012 and Spring 2013 combined?#

SELECT Count(*)
from User_Course_Registration as T1
join Course_details as T2
on T1.Course_id = T2.Course_id
where T2.course_number = '6.00x'
and T2.Institution = 'MITx'
and T2.course_term in ('2012_Fall', '2013_Spring')
and T1.Registered = 1;


-- Question 4: What was the average grade in each term of 6.00x,
-- excluding all the zeros for people who have not taken any tests.

SELECT distinct course_term,
avg(Grade) over (partition by course_term) as Avg_Grade
from User_Course_Registration as T1
join Course_details as T2
on T1.Course_id = T2.Course_id
where grade > 0
and T2.course_number = '6.00x';

-- What was the total number of people registered in each course offered (during all terms)?

SELECT course_number, count(*) as total
from User_Course_Registration as T1
inner join Course_details as T2
on T1.Course_id = T2.Course_id
where T1.Registered = 1
group by course_number;

-- List courses that are hosted at Harvard, and have at least 2000 enrollees (registered).
-- Order these courses according to the number of enrollees from the largest to the smallest,
--   and according to the term during when they were offered.


SELECT course_number, course_term,count(*) as total
from User_Course_Registration as T1
inner join Course_details as T2
on T1.Course_id = T2.Course_id
where T2.Institution = 'HarvardX'
and T1.Registered = 1
group by course_number, course_term
having count(*) > 2000
order by course_term, total desc;

-- For each course, how many people are registered, have viewed,
--  have explored, and have become certified?
--  Group the courses by Course_Long_Title.

SELECT course_number,Course_Long_Title,
SUM(CASE WHEN T1.Registered = 1 THEN 1
	ELSE 0 END) AS Registered,
SUM(CASE WHEN T1.Viewed = 1 THEN 1
	ELSE 0 END) as Viewed,
SUM(CASE WHEN T1.Explored = 1 THEN 1
	ELSE 0 END) as Explored,
SUM(CASE WHEN T1.Certified = 1 THEN 1
	ELSE 0 END) as Certified
from User_Course_Registration as T1
inner join Course_details as T2
on T1.Course_id = T2.Course_id
group by Course_Long_Title;

-- What fraction of users view, explore, or certify in the content
--  in each course once they have registered?
--  Group the courses by Course_Long_Title.

SELECT course_number,Course_Long_Title,
(SUM(CASE WHEN T1.Viewed = 1 THEN 1
	ELSE 0 END) / SUM(CASE WHEN T1.Registered = 1 THEN 1
	ELSE 0 END)) as Viewed,
(SUM(CASE WHEN T1.Explored = 1 THEN 1
	ELSE 0 END)/ SUM(CASE WHEN T1.Registered = 1 THEN 1
	ELSE 0 END)) as Explored,
(SUM(CASE WHEN T1.Certified = 1 THEN 1
	ELSE 0 END)/SUM(CASE WHEN T1.Registered = 1 THEN 1
	ELSE 0 END)) as Certified
from User_Course_Registration as T1
inner join Course_details as T2
on T1.Course_id = T2.Course_id
where T1.Registered = 1
group by Course_Long_Title;

-- List the classes taught at Harvard with more than 1500 enrollees.
--  Group the classes according to the term during which they were offered, and
--  Order them according to the number of enrollees in descending order.

SELECT course_number, course_term, count(*) as total
from User_Course_Registration as T1
inner join Course_details as T2
on T1.Course_id = T2.Course_id
where T2.Institution = 'HarvardX'
and T1.Registered = 1
group by course_number
having count(*) > 1500
order by course_number asc, course_term;

-- List Users who have registered for more than three courses.
--  Include user's ID, age, country, level of education, and the number of
--  courses registered.
--  Order the list according to the number of courses that the user has registered in.

SELECT  T1.Userid_DI, Age, Country, LoE_DI,
Count(course_id) as num_courses
from User_Course_Registration as T1
inner join User_details as T2
on T1.Userid_DI = T2. Userid_DI
group by Userid_DI
having Count(course_id) > 3
order by  Count(course_id);

-- How many users are there by country, ordered alphabetically,
--  and not including those whose 'Country' is indicated to be 'Unknown/Other' or 'Other'.


SELECT country, count(*) as total
from user_details
where country is not null
and Country not in ('Unknown/Other','Other')
group by country
order by country;

-- For each country, what tis the average grade for the certified users?
--  Do not include those whose 'Country' is labeled as 'Unknown/Other' or 'Other".
--  Also, do not include users with a NULL grade.
--  Sort the list from the highest average to the lowest.


SELECT distinct country, avg(grade) as avg_grade
from User_Course_Registration as T1
inner join User_details as T2
on T1.Userid_DI = T2. Userid_DI
where T1.Certified = 1
and grade is not null
and Country not in ('Unknown/Other','Other')
group by Country
order by avg_grade desc;

-- For each country, what is the average grade for the certified users
--   at Harvard, excluding countries whose name start with "Other"?
--   Order the list according to the average grades from the highest to the lowest.


SELECT distinct country, avg(grade) as avg_grade
from User_Course_Registration as T1
inner join User_details as T2
on T1.Userid_DI = T2. Userid_DI
inner join Course_details as T3
on T1.Course_id = T3.Course_id
where T1.Certified = 1
and T3.Institution = 'HarvardX'
and grade is not null
and country not like 'Other %'
group by Country
order by avg_grade desc;

-- Rank each student, across all terms and in each of the 6.002x courses (in descending order),
--  according to his/her grade in this course, across all terms.

SELECT T1.Userid_DI, course_term, grade
from User_Course_Registration as T1
inner join User_details as T2
on T1.Userid_DI = T2. Userid_DI
inner join Course_details as T3
on T1.Course_id = T3.Course_id
where T3.Course_number = '6.002x'
and grade is not null and grade > 0
order by grade desc;











--  ------------------------------------------------------------------
--  ------------------------------------------------------------------

-- END


--  ------------------------------------------------------------------
--  ------------------------------------------------------------------
