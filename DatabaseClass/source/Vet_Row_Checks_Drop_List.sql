
-- queries to check and record results in Veterinary Hospital --
select * from breedissues -- 14 Rows
select * from diagnosticlookup -- 14 Rows
select * from breedspecies -- 25 Rows
select * from pet order by pet_id -- 65 Rows
select * from InsProvider -- 10 Rows
select * from owner order by owner_id -- 224 Rows
select * from medication -- 72 Rows
select * from pet_has_owner -- 65 Rows
select * from prescription order by prescription_id-- 200 Rows
select * from procedurelookup -- 84 Rows
select * from appttype -- 5 Rows
select * from appointment order by appointment_id -- 14608 Rows
select * from visit -- 13156 Rows
select * from diagnosis -- 200 Rows
select * from procedure -- 10000 Rows
select * from billing order by bill_id -- 11655 Rows
select * from payment -- 11621 Rows
select * from account order by acct_bal -- 234 Rows

drop table account;
drop table payment;
drop table billing;
drop table procedure;
drop table prescription;
drop table diagnosis;
drop table visit;
drop table appointment;
drop table appttype;
drop table procedurelookup;
drop table pet_has_owner;
drop table medication;
drop table owner;
drop table insprovider;
drop table pet;
drop table breedspecies;
drop table diagnosticlookup;
drop table breedissues;
